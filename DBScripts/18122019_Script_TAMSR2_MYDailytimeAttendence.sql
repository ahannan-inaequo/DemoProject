IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAMSR2_MYDailytimeAttendence]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[TAMSR2_MYDailytimeAttendence]
GO


IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[TAMSR2_MYDailytimeAttendence]') AND type in (N'P', N'PC'))
BEGIN
EXEC dbo.sp_executesql @statement = N'CREATE PROCEDURE [dbo].[TAMSR2_MYDailytimeAttendence] AS' 
END
GO


-- =============================================
-- Author:		Asim
-- Create date: 2013-05-28
-- Date Update: 2018-03-05 {Update the Expected Timeout as to OutTime1 if employee has punched before InTime1}
-- Description:	All operations performed in this procedure on Organization_Types depends upon parameters
-- Parameters :	@action parameter will identify which operation will be performed in this procedure, 
--				@sessionID parameter will identify login user ID who requested for particular operation
--				and all other parameters will be passed as required for particular operation
-- =============================================
ALTER PROCEDURE [dbo].[TAMSR2_MYDailytimeAttendence] 
@action           NVARCHAR(100) = '',
@sessionID        NVARCHAR(20) = '',
@ID               NVARCHAR(20) = '',
@date             NVARCHAR(25) = '',
@Todate           NVARCHAR(25) = '',
@type             NVARCHAR(200) = '',
@scope            NVARCHAR(25) = '',
@searchInput      NVARCHAR(200) = '',
@orderBy          NVARCHAR(200) = '',
@startRow         NVARCHAR(18) = '',
@endRow           NVARCHAR(18) = '',
@MemberId		  NVARCHAR(10) = '',
@OrganizationCode NVARCHAR(20) = '',
@OrganizationID	  NVARCHAR(10) = '', 
@ManagerID		  NVARCHAR(10) = '',
@EmployeeID		  NVARCHAR(10) = '',
@IsArabic		  NVARCHAR(1) = N'',
@activityLastTransactionTime nvarchar(20) = ''

AS
  BEGIN
      DECLARE @query NVARCHAR(max)
      DECLARE @query1 NVARCHAR(max)
      DECLARE @param NVARCHAR(max)
      DECLARE @privilegeID NUMERIC
      DECLARE @TimeIn VARCHAR(25)
      DECLARE @TimeOut VARCHAR(25)
      DECLARE @SchID VARCHAR(25)
      DECLARE @SchCode NVARCHAR(25)
      DECLARE @Flexible VARCHAR(25)
      DECLARE @GraceIn VARCHAR(25)
      DECLARE @GraceOut VARCHAR(25)
      DECLARE @InTime1 VARCHAR(25)
      DECLARE @OutTime1 VARCHAR(25)
      DECLARE @RequireTime1 INT
      DECLARE @InTime2 VARCHAR(25)
      DECLARE @OutTime2 VARCHAR(25)
      DECLARE @RequireTime2 INT
      DECLARE @InTime3 VARCHAR(25)
      DECLARE @OutTime3 VARCHAR(25)
      DECLARE @RequireTime3 INT
      DECLARE @Early VARCHAR(25)
      DECLARE @Late VARCHAR(25)
      DECLARE @Absent VARCHAR(25)
      DECLARE @MissedIN VARCHAR(25)
      DECLARE @MissedOut VARCHAR(25)
      DECLARE @Leave VARCHAR(25)
      DECLARE @Permission VARCHAR(25)
      DECLARE @EarlyMinutes VARCHAR(25)
      DECLARE @LateMinutes VARCHAR(25)
      DECLARE @AbsentMinutes VARCHAR(25)
      DECLARE @PermissionMinutes VARCHAR(25)
      DECLARE @MonthlyEarly VARCHAR(25)
      DECLARE @MonthlyLate VARCHAR(25)
      DECLARE @MonthlyAbsent VARCHAR(25)
      DECLARE @MonthlyPermission VARCHAR(25)
      DECLARE @MonthlyEarlyMinutes VARCHAR(25)
      DECLARE @MonthlyLateMinutes VARCHAR(25)
      DECLARE @MonthlyAbsentMinutes VARCHAR(25)
      DECLARE @MonthlyPermissionMinutes VARCHAR(25)
      DECLARE @GroupEarly VARCHAR(max)
      DECLARE @GroupLate VARCHAR(max)
      DECLARE @GroupAbsent VARCHAR(max)
      DECLARE @GroupLeave VARCHAR(max)
      DECLARE @GroupPermission VARCHAR(max)
      DECLARE @GroupEarlyMinutes VARCHAR(25)
      DECLARE @GroupLateMinutes VARCHAR(25)
      DECLARE @GroupAbsentMinutes VARCHAR(25)
      DECLARE @GroupRequiredHours VARCHAR(25)
      DECLARE @GroupAchievedHours VARCHAR(25)
      DECLARE @GroupAchievedHoursPercent VARCHAR(25)
      DECLARE @MonthlyGroupEarly VARCHAR(25)
      DECLARE @MonthlyGroupLate VARCHAR(25)
      DECLARE @MonthlyGroupAbsent VARCHAR(25)
      DECLARE @MonthlyGroupRequiredHours VARCHAR(25)
      DECLARE @MonthlyGroupAchievedHours VARCHAR(25)
      DECLARE @MonthlyGroupAchievedHoursPercent VARCHAR(25)
      DECLARE @MonthlyGroupEarlyMinutes VARCHAR(25)
      DECLARE @MonthlyGroupLateMinutes VARCHAR(25)
      DECLARE @MonthlyGroupAbsentMinutes VARCHAR(25)
      DECLARE @tempPermission VARCHAR(25)
      DECLARE @userID NUMERIC
	  Declare @Present int = 0 
      Declare @Outside int = 0 
	  Declare @Required int= 0
	  Declare @Actual int = 0

      SELECT @userID = user_id
      FROM   sec_users
      WHERE  employee_id = @sessionID

      SET @query = ''
      SET @query1 = ''

      DECLARE @dt DATETIME
      DECLARE @dtNext DATETIME

      SET @dt = CONVERT(DATETIME, @date, 121)
      SET @dtNext = Dateadd(day, 1, @dt)
	  if(@Todate != '')
	  begin

		 SET @Todate = CONVERT(DATETIME, @Todate, 121) 
		 SET @Todate = Dateadd(day, 1, @Todate)
		  
		 SET @dtNext = CONVERT(DATETIME, @Todate, 121) 
		 SET @dtNext = Dateadd(day, 1, @Todate)
	  end
      DECLARE @firstDay DATETIME
      DECLARE @lastDay DATETIME

      SET @firstDay = CONVERT(VARCHAR(25), Dateadd(dd, -( Day(@dt) - 1 ), @dt),
                      121)
      SET @lastDay = CONVERT(VARCHAR(25), Dateadd(dd, -( Day(Dateadd(mm, 1, @dt)
                                                         )
                                                       ),
                                                         Dateadd(mm, 1, @dt)),
                     121
                     )

      IF @startRow = ''
        SET @startRow = 0

      IF @endRow = ''
        SET @endRow = 10

      SET @endRow = CONVERT(NUMERIC, @startRow)
                    + CONVERT(NUMERIC, @endRow);
	
	IF @OrganizationID = 'undefined'
		SET @OrganizationID = NULL
	IF @ManagerID = 'undefined'
		SET @ManagerID = NULL
	IF @EmployeeID = 'undefined'
		SET @EmployeeID = NULL
	
	CREATE TABLE #copyOrgID(OrgID NUMERIC)
      ---------------------------------------------------------------------
      ---------------- GET My Daily Time Attendance -----------------------
      ---------------------------------------------------------------------
      IF @action = 'getTransactions'
        BEGIN
            SET @searchInput = '''%' + @searchInput + '%''';

			IF @date != '' and @Todate != ''
			BEGIN
				set @query1 = 'and empTrans.transaction_time>='''+ CONVERT(VARCHAR(19), @dt, 121) + '''
							   and empTrans.transaction_time <'''+ CONVERT(VARCHAR(19), Convert(datetime,@Todate), 121)+ ''''
			END			
			ELSE 
			BEGIN
			   set @query1 ='and empTrans.transaction_time>='''+ CONVERT(VARCHAR(19), @dt, 121) + '''
							   and empTrans.transaction_time <'''+ CONVERT(VARCHAR(19), @dtNext, 121)+ ''''
			END 

            SET @query = 'SELECT  * FROM     
			( SELECT    ROW_NUMBER() OVER (  order by '
                         + @orderBy + ' ) AS RowNum, 
				empTrans.employee_id, empTrans.transaction_time, empTrans.user_entry_flag, 
				emp.name_eng, emp.name_arb, emp.employee_code, rsn.description_eng reason_eng, 
				rsn.description_arb reason_arb, rg.description_eng region_eng, rg.description_arb region_arb, rdr.reader_name
			from employee_event_transactions empTrans, employee_master emp, reasons rsn, readers rdr, regions rg
			where 
				empTrans.employee_id='
                         + CONVERT(VARCHAR, @sessionID)
                         + ' ' + @query1 +  ' 
				 
				and empTrans.employee_id=emp.employee_id 
				and empTrans.reason_id=rsn.reason_id 
				and empTrans.reader_id=rdr.reader_id 
				and rdr.region_id=rg.region_id 
				and 
				(
					emp.employee_code Like '
                         + @searchInput + ' or emp.name_eng Like '
                         + @searchInput + ' or emp.name_arb Like '
                         + @searchInput
                         + ' or 
					rg.description_eng Like '
                         + @searchInput
                         + ' or rg.description_eng Like '
                         + @searchInput + '
				)
			) AS RowConstrainedResult
		WHERE   RowNum > '
                         + @startRow + ' AND RowNum <= ' + @endRow;

            PRINT @query;

            EXEC(@query);

            RETURN;
        END

      IF @action = 'getTransactionsCount'
        BEGIN
            IF @startRow = ''
              SET @startRow = 0

            IF @endRow = ''
              SET @endRow = 10

            SET @endRow = CONVERT(NUMERIC, @startRow)
                          + CONVERT(NUMERIC, @endRow);
            SET @searchInput = '''%' + @searchInput + '%''';
            SET @query = 'select Count(empTrans.transaction_time)
			from employee_event_transactions empTrans, employee_master emp, reasons rsn, readers rdr, regions rg
		where 
			empTrans.employee_id=' + @sessionID
                         + ' and 
			empTrans.transaction_time >= '''
                         + CONVERT(VARCHAR, @dt, 121)
                         + ''' and empTrans.transaction_time < '''
                         + CONVERT(VARCHAR, @dtNext, 121)
                         + ''' 
			and empTrans.employee_id=emp.employee_id 
			and empTrans.reason_id=rsn.reason_id 
			and empTrans.reader_id=rdr.reader_id 
			and rdr.region_id=rg.region_id 
			and 
			(
			emp.employee_code Like ' + @searchInput
                         + ' or emp.name_eng Like ' + @searchInput
                         + ' or emp.name_arb Like  ' + @searchInput
                         + ' or 
			rg.description_eng Like  '
                         + @searchInput
                         + ' or rg.description_eng Like  '
                         + @searchInput + '
			)'
			print @query
            EXEC( @query)

            RETURN;
        END

      IF @action = 'getStats'
        BEGIN
            DECLARE @todayDate VARCHAR(25)
			 
            SET @todayDate = CONVERT(VARCHAR(10), Getdate(), 121)
                             + ' 00:00:00'

            SELECT TOP 1  @Actual = ISNULL (DATEDIFF(Minute, Time_In, Time_Out),'')
            FROM   daily_employeeattendancedetails
            WHERE  employee_id = @sessionID
                   AND ddate = @dt
            ORDER  BY daily_employeeattendancedetails_id ASC

            SELECT TOP 1 @TimeIn = time_in
            FROM   daily_employeeattendancedetails
            WHERE  employee_id = @sessionID
                   AND ddate = @dt
            ORDER  BY daily_employeeattendancedetails_id ASC

            IF @SchID IS NULL
              SELECT @SchID = dbo.Fn_getscheduleid(@sessionID, @dt)

            SELECT TOP 1 @TimeOut = time_out
            FROM   daily_employeeattendancedetails
            WHERE  employee_id = @sessionID
                   AND ddate = @dt
            ORDER  BY daily_employeeattendancedetails_id DESC

            SELECT TOP 1 @SchCode = schedule_code,
                         @Flexible = flexible_min,
                         @GraceIn = grace_in_min,
                         @GraceOut = grace_out_min,
                         @InTime1 = in_time1,
                         @OutTime1 = out_time1,
                         @InTime2 = in_time2,
                         @OutTime2 = out_time2,
                         @InTime3 = in_time3,
                         @OutTime3 = out_time3
            FROM   schedules
            WHERE  schedule_id = @SchID

            IF CONVERT(DATETIME, @InTime1, 121) >
               CONVERT(DATETIME, @OutTime1, 121)
              BEGIN
                  SET @OutTime1 = Dateadd(day, 1, @OutTime1)
              END

            IF CONVERT(DATETIME, @InTime2, 121) >
               CONVERT(DATETIME, @OutTime2, 121)
              BEGIN
                  SET @OutTime2 = Dateadd(day, 1, @OutTime2)
              END

            IF CONVERT(DATETIME, @InTime3, 121) >
               CONVERT(DATETIME, @OutTime3, 121)
              BEGIN
                  SET @OutTime3 = Dateadd(day, 1, @OutTime3)
              END

            SET @RequireTime1 = Datediff(minute, @InTime1, @OutTime1)
            SET @RequireTime2 = Datediff(minute, @InTime2, @OutTime2)
            SET @RequireTime3 = Datediff(minute, @InTime3, @OutTime3)

            EXEC Pr_employeetransdetails
              @EmployeeId = @sessionID,
              @FromDate = @dt,
              @ToDate = @dt,
              @UserID = @userID,
              @UpdateAll = 1

            --EXEC pr_MainTransDetails @CompanyID = 1, @OrganizationID = NULL, @EmployeeId = @sessionID, @FromDate = @dt, @ToDate = @dt, @UserId = @userID, @UpdateAll = NULL
            SELECT @Early = Count(*),
                   @EarlyMinutes = Sum(early)
            FROM   daily_employeeattendancedetails
            WHERE  ddate = @dt
                   AND early > 0
                   AND isnull(early_approved,0) = 0
                   AND employee_id = @sessionID

            SELECT @Late = Count(*),
                   @LateMinutes = Sum(late)
            FROM   daily_employeeattendancedetails
            WHERE  ddate = @dt
                   AND late > 0
                   AND (isnull(late_approved,0) = 0)
                   AND employee_id = @sessionID

            SELECT @Absent = Count(*),
                   @AbsentMinutes = Sum(absentmts)
            FROM   daily_employeeattendancedetails
            WHERE  ddate = @dt
                   AND absent > 0
                   AND (isnull(absent_approved,0) = 0)
                   AND employee_id = @sessionID

            SELECT @Leave = Count(*)
            FROM   daily_employeeattendancedetails
            WHERE  ddate = @dt
                   AND leave > 0
                   AND employee_id = @sessionID
				   


			SELECT @MissedIN = Count(*) 
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
				   AND ddate <= @dt --ddate = @dt
                   AND Time_In is null 
                   AND Time_Out is not null
                   AND employee_id = @sessionID
				   AND ISNULL(LEAVE,0) = 0
				   AND ISNULL(restday,0) = 0
				   AND ISNULL(holiday,0) = 0

			if(@dt = CONVERT(DATE,GETDATE(),121))
			BEGIN
				   SELECT @MissedOut = Count(*) 
				   FROM   daily_employeeattendancedetails
				   WHERE  ddate >= @firstDay
						 AND ddate <= @dt - 1 
						 AND Time_In is not null 
                         AND Time_Out is  null
						 AND employee_id = @sessionID
					     AND ISNULL(LEAVE,0) = 0
					     AND ISNULL(restday,0) = 0
					     AND ISNULL(holiday,0) = 0
			END
			ELSE
			BEGIN
				   SELECT @MissedOut = Count(*) 
				   FROM   daily_employeeattendancedetails
				   WHERE  ddate >= @firstDay
						AND ddate <= @dt --ddate = @dt
						AND Time_In is not null 
                        AND Time_Out is  null
						AND employee_id = @sessionID
						AND ISNULL(LEAVE,0) = 0
						AND ISNULL(restday,0) = 0
						AND ISNULL(holiday,0) = 0
			END
			
			SELECT @Permission = Count(*),
                   @PermissionMinutes = Sum(minutes)
            FROM   single_permissions
            WHERE  @dt  between from_date and to_date
                   AND employee_id = @sessionID
				   
			SELECT @MonthlyPermission = Count(*),
                   @MonthlyPermissionMinutes = Sum(minutes)
            FROM   single_permissions
            WHERE  from_date>= @firstDay  and to_date <= @dt  
                   AND employee_id = @sessionID


            SELECT @MonthlyEarly = Count(*),
                   @MonthlyEarlyMinutes = Sum(early)
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
                    AND ddate <= @dt
                   AND isnull(early,0) > 0
                   AND (early_approved = 0 OR early_approved is null)
                   AND employee_id = @sessionID

            SELECT @MonthlyLate = Count(*),
                   @MonthlyLateMinutes = Sum(late)
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
               AND ddate <= @dt
                   AND isnull(late,0) > 0
                   AND (late_approved = 0 OR late_approved is null)
                   AND employee_id = @sessionID

            SELECT @MonthlyAbsent = Count(*),
                   @MonthlyAbsentMinutes = Sum(absentmts)
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
                   AND ddate <= @dt
                   AND isnull(absent,0) > 0
                   AND (absent_approved = 0  OR absent_approved is null)
                   AND employee_id = @sessionID

            SELECT @Leave = Count(*)
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
                     AND ddate <= @dt
                   AND leave > 0
                   AND employee_id = @sessionID

            IF EXISTS(SELECT 1
                      FROM   employee_master
                      WHERE  manager_flag = 'Y'
                             AND employee_id = @sessionID)
              BEGIN
                  --select  @dt 
                  SELECT @GroupEarly = Count(*),
                         @GroupEarlyMinutes = Sum(early)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate = @dt
                         AND early > 0
                         AND isnull(early_approved,0) = 0
                         AND employee_id IN (SELECT employee_id
                                             FROM   employee_master
                                             WHERE  manager_id = @sessionID)

                  SELECT @GroupLate = Count(*),
                         @GroupLateMinutes = Sum(late)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate = @dt
                         AND late > 0
                         AND isnull(late_approved,0) = 0
                         AND employee_id IN (SELECT employee_id
                                             FROM   employee_master
                                             WHERE  manager_id = @sessionID)

                  SELECT @GroupAbsent = Count(*),
                         @GroupAbsentMinutes = Sum(absentmts)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate = @dt
                         AND absent > 0
                         AND isnull(absent_approved,0) = 0
                         AND employee_id IN (SELECT employee_id
                                             FROM   employee_master
                                             WHERE  manager_id = @sessionID)

                  SELECT @MonthlyGroupEarly = Count(*),
                         @MonthlyGroupEarlyMinutes = Sum(early)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate >= @firstDay
                         AND ddate <= @lastDay
                         AND early > 0
                         AND isnull(early_approved,0) = 0
                         AND employee_id IN (SELECT employee_id
                                             FROM   employee_master
                                             WHERE  manager_id = @sessionID)

                  SELECT @MonthlyGroupLate = Count(*),
                         @MonthlyGroupLateMinutes = Sum(late)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate >= @firstDay
                         AND ddate <= @lastDay
                         AND late > 0
                         AND isnull(late_approved,0) = 0
                         AND employee_id IN (SELECT employee_id
                                             FROM   employee_master
                                             WHERE  manager_id = @sessionID)

                  SELECT @MonthlyGroupAbsent = Count(*),
                         @MonthlyGroupAbsentMinutes = Sum(absentmts)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate >= @firstDay
                         AND ddate <= @lastDay
                         AND isnull(absent,0) > 0
                         AND absent_approved = 0
                         AND employee_id IN (SELECT employee_id
                                             FROM   employee_master
                                             WHERE  manager_id = @sessionID)


              END

IF (select value  from app_setting where vname = 'CALCULATE_EARLY_DAY_END') = 'yes' and CONVERT(date,@dt,121) =  CONVERT(date,getdate(),121)
					BEGIN
							
					update daily_EmployeeAttendanceDetails set early = null  WHERE  ddate = @dt  
					AND early > 0
					AND early_approved = 0
					AND employee_id = @sessionID
					set @EarlyMinutes = null
									

					--update daily_EmployeeAttendanceDetails set early = null  WHERE  ddate = @dt
					--AND early > 0
					--AND early_approved = 0
					--AND employee_id = @sessionID
					--set @EarlyMinutes = null


					END

            SELECT CONVERT(TIME, @TimeIn)                                 TimeIn
                   ,
                   CONVERT(TIME, @TimeOut)
                   TimeOut,
                   @SchCode
                   SchCode,
                   @Late                                                  Late,
                   @Early                                                 Early,
                   @Absent                                                Absent
                   ,
                   @Leave
                   Leave,
                   dbo.Fn_gettimeformat(Isnull(@LateMinutes, 0))
                   LateMinutes,
                   dbo.Fn_gettimeformat(Isnull(@EarlyMinutes, 0))
                   EarlyMinutes
                   ,
                   dbo.Fn_gettimeformat(Isnull(@AbsentMinutes, 0))
                   AbsentMinutes,
                   @MonthlyLate
                   MonthlyLate,
                   @MonthlyEarly
                   MonthlyEarly
                   ,
                   @MonthlyAbsent
                   MonthlyAbsent,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyLateMinutes, 0))
                   MonthlyLateMinutes
                   ,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyEarlyMinutes, 0))
                   MonthlyEarlyMinutes,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyAbsentMinutes, 0))
                   MonthlyAbsentMinutes,
                   @GroupLate
                   GroupLate,
                   @GroupEarly
                   GroupEarly,
                   @GroupAbsent
                   GroupAbsent,
                   dbo.Fn_gettimeformat(Isnull(@GroupLateMinutes, 0))
                   GroupLateMinutes,
                   dbo.Fn_gettimeformat(Isnull(@GroupEarlyMinutes, 0))
                   GroupEarlyMinutes,
                   dbo.Fn_gettimeformat(Isnull(@GroupAbsentMinutes, 0))
                   GroupAbsentMinutes
                   ,
                   @MonthlyGroupLate
                   MonthlyGroupLate,
                   @MonthlyGroupEarly
                   MonthlyGroupEarly,
                   @MonthlyGroupAbsent
                   MonthlyGroupAbsent
                   ,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyGroupLateMinutes, 0))
                   MonthlyGroupLateMinutes,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyGroupEarlyMinutes, 0))
                   MonthlyGroupEarlyMinutes,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyGroupAbsentMinutes, 0))
                   MonthlyGroupAbsentMinutes,
                   @Flexible
                   Flexible
                   ,
                   @GraceIn
                   GraceIn,
                   @GraceOut
                   GraceOut
                   ,
                   CONVERT(TIME, @InTime1)
                   InTime1,
                   CONVERT(TIME, @OutTime1)
                   OutTime1
                   ,
                   Isnull(@RequireTime1, 0)
                   RequireTime1
                   ,
                   CONVERT(TIME, @InTime2)
     InTime2,
                   CONVERT(TIME, @OutTime2)
                   OutTime2
                   ,
                   Isnull(@RequireTime2, 0)
                   RequireTime2
                   ,
                   CONVERT(TIME, @InTime3)
                   InTime3,
            CONVERT(TIME, @OutTime3)
                   OutTime3
                   ,
                   Isnull(@RequireTime3, 0)
                   RequireTime3
                   ,
				   --case 
				   --when (
       --            Isnull(Dateadd(minute, Isnull(@RequireTime1, 0),
       --                   CONVERT(TIME, case   when convert(varchar(5),convert(datetime,@TimeIn),108)
						 --  <convert(varchar(5),convert(datetime,@InTime1),108) then @InTime1 else @TimeIn end )),
       --            '00:00') > CONVERT(VARCHAR(5), (Dateadd(minute, CONVERT(INT,isnull( @Flexible,0)), CONVERT( TIME, @outtime1))))) 
							--then CONVERT(VARCHAR(5), (Dateadd(minute, CONVERT(INT,isnull( @Flexible,0)), CONVERT( TIME, @outtime1))))  	
								
								
								
							--	else ( Isnull(Dateadd(minute, Isnull(@RequireTime1, 0), CONVERT(TIME, case   when convert(varchar(5),convert(datetime,@TimeIn),108) <convert(varchar(5),convert(datetime,@InTime1),108) then @InTime1 else @TimeIn end )), '00:00'))
							--		end

			dbo.fnExpectedTimeOUT (@TimeIn ,@RequireTime1 ,convert(varchar(5),convert(datetime,@InTime1),108), convert(varchar(5),convert(datetime,@OutTime1),108),@Flexible )
                   ExpectedTimeOut,
                   CONVERT(VARCHAR(5), CONVERT(TIME, @OutTime1))
                   + ' - '
                   + CONVERT(VARCHAR(5), (Dateadd(minute, CONVERT(INT,isnull( @Flexible,0)), CONVERT( TIME, @outtime1)))
				   )                                          AS
                   SchWithFlexible,
				   @MissedIN as MissedIN,
				   @MissedOut as MissedOut,
				   @Permission Permission,
				   dbo.Fn_gettimeformat(Isnull(@PermissionMinutes, 0))  PermissionMinutes,
				   @MonthlyPermission MonthlyPermission,
				   dbo.Fn_gettimeformat(Isnull(@MonthlyPermissionMinutes, 0))  MonthlyPermissionMinutes,
				   @Actual as Actual

			            RETURN;
        END

      IF @action = 'getGroupStats'
        BEGIN
            DECLARE @tempDay DATETIME
            DECLARE @tempLate INT
            DECLARE @tempEarly INT
            DECLARE @tempLeave INT
            DECLARE @tempAbsent INT
            DECLARE @tempMissedIn INT
            DECLARE @tempMissedOut INT
			DECLARE @GroupMissedIn nvarchar(max)
			DECLARE @GroupMissedOut nvarchar(max)
            SET @tempDay = @firstDay

            SELECT @privilegeID = privilege_id
            FROM   sec_privileges
            WHERE  privilege_id IN (SELECT privilege_id
                                    FROM   sec_role_privileges
                                    WHERE  role_id IN (SELECT role_id
                                                       FROM   sec_user_roles
                                                       WHERE  user_id = @userID)
                                   )
                   AND privilege_name = 'VIEW_EMPLOYEE'

            CREATE TABLE #tbl(empid NUMERIC)
			

            --insert into #tbl exec sec_get_employeeids @userID, @privilegeID
            INSERT INTO #tbl  
			EXEC dbo.Sec_get_node_emp_ids @userID,@privilegeID,0,'E'
			 
			IF @OrganizationID != ''
			BEGIN
				INSERT INTO #copyOrgID
				EXEC USP_GET_ORGANIZATIIONS_HIERARCHY_BY_ORGANIZATIONID @OrganizationID
			END

			INSERT INTO #tbl exec dbo.sec_get_DeptAdmin_employeeids @SessionID, @privilegeID, 'E', '' 

			IF(@OrganizationID != '')
				DELETE FROM #tbl WHERE empID not in (select employee_id from employee_master where organization_id IN (select OrgID from #copyOrgID)) 

			IF(ISNULL(@ManagerID,'') != '')
			   delete from #tbl where empID not in (select employee_id from employee_master where manager_id =  @ManagerID) 

			IF Rtrim(Ltrim(Isnull(@EmployeeID, ''))) != ''
				DELETE #tbl WHERE  empid <> @EmployeeID


            CREATE TABLE #tblfreq
              (
                 ddate  DATETIME,
                 late   INT,
                 early  INT,
                 leave  INT,
                 absent INT,
        MissedIn INT,
                 MissedOut INT,
				 Permission INT
              )



            DECLARE @totalEmp VARCHAR(5)
            DECLARE @noOfDays VARCHAR(5)

            SELECT @noOfDays = Day(Eomonth(@lastDay))

            SELECT @totalEmp = 0--Count(empid)
            FROM   #tbl

			--select @tempDay, @dt
            --select @totalEmp = (count(empID) * @noOfDays) from #tbl
            --INSERT INTO #tblfreq    
            --VALUES      (@tempDay,
            --             @totalEmp,
            --             @totalEmp,
            --             @totalEmp,
            --             @totalEmp,
            --             @totalEmp,
            --             @totalEmp,
            --             @totalEmp,
            --             @totalEmp)

            WHILE @tempDay <= @lastDay
              BEGIN
				
				 IF @tempDay <= @dt
				 begin
					  SELECT @tempLate = Isnull(Count(*), 0)
					  FROM   daily_employeeattendancedetails
					  WHERE  ddate = @tempDay
							 AND late > 0
							 AND employee_id IN (SELECT empid
												FROM   #tbl)
				end
				ELSE
					SET @tempLate = 0

                IF @tempDay <= @dt
				 begin
					  SELECT @tempEarly = Isnull(Count(*), 0)
					  FROM   daily_employeeattendancedetails
					  WHERE  ddate = @tempDay
							 AND early > 0
							 AND employee_id IN (SELECT empid
												 FROM   #tbl)
				 end
				 else
					SET @tempEarly = 0

                IF @tempDay <= @dt
				 begin
				   SELECT @tempLeave = Isnull(Count(*), 0)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate = @tempDay
                         AND leave > 0
                         AND employee_id IN (SELECT empid
                                             FROM   #tbl)
				end
				else
						SET @tempLeave = 0

                IF @tempDay <= @dt
				 begin
					   SELECT @tempAbsent = Isnull(Count(*), 0)
					   FROM   daily_employeeattendancedetails
					   WHERE  ddate = @tempDay
							 AND absent > 0
							 AND employee_id IN (SELECT empid
                                             FROM   #tbl)
                end
				else
						SET @tempAbsent = 0
				IF @tempDay <= @dt
				 begin
						SELECT @tempMissedIn = Isnull(Count(*), 0)
						FROM   daily_employeeattendancedetails
						WHERE  ddate = @tempDay
							 AND Time_In IS NULL AND Time_Out IS NOT NULL
							 AND ISNULL(LEAVE,0) = 0
							 AND ISNULL(restday,0) = 0
							 AND ISNULL(holiday,0) = 0 
							 AND employee_id IN (SELECT empid
												 FROM   #tbl)
				end
				else
					SET @tempMissedIn = 0
                IF(@tempDay = Convert(date,getdate(),121) OR @tempDay > @dt)
				BEGIN
					SET @tempMissedOut = 0
				END
				ELSE
				BEGIN
				SELECT @tempMissedOut = Isnull(Count(*), 0)
                  FROM   daily_employeeattendancedetails
                  WHERE  ddate = @tempDay
                         AND Time_In IS NOT NULL AND Time_Out IS NULL
                         AND employee_id IN (SELECT empid
                                             FROM   #tbl)
					    AND ISNULL(LEAVE,0) = 0
					    AND ISNULL(restday,0) = 0
					    AND ISNULL(holiday,0) = 0
				END 
				
				IF @tempDay <= @dt
				 begin  
					  SELECT @tempPermission = Isnull(Count(*), 0)
					  FROM   single_permissions 
					  WHERE  
							 permission_type_id in (select permission_type_id from permission_types where code = 'Personal') and
							 Convert(nvarchar(10),from_date,121) = Convert(nvarchar(10),@tempDay,121) and Convert(nvarchar(10),to_date,121) = Convert(nvarchar(10),@tempDay,121)
							 AND employee_id IN (SELECT empid
												 FROM   #tbl)
                 end
				 else
					 SET @tempPermission = 0 

				  INSERT INTO #tblfreq
                  VALUES      (@tempDay,
                               @tempLate,
                               @tempEarly,
                              @tempLeave,
                               @tempAbsent,
							   @tempMissedIn,
							   @tempMissedOut,
							   @tempPermission)

                  SET @tempDay = Dateadd(day, 1, @tempDay)
              END

            SELECT @GroupLate = COALESCE(@GroupLate + ', ', '')
                                + CONVERT(VARCHAR, late)
            FROM   #tblfreq

            SELECT @GroupEarly = COALESCE(@GroupEarly + ', ', '')
                                 + CONVERT(VARCHAR, early)
            FROM   #tblfreq

            SELECT @GroupLeave = COALESCE(@GroupLeave + ', ', '')
                                 + CONVERT(VARCHAR, leave)
            FROM   #tblfreq

            SELECT @GroupAbsent = COALESCE(@GroupAbsent + ', ', '')
                                  + CONVERT(VARCHAR, absent)
            FROM   #tblfreq

            SELECT @GroupMissedIn = COALESCE(@GroupMissedIn + ', ', '')
                                  + CONVERT(VARCHAR, MissedIn)
            FROM   #tblfreq
			
            SELECT @GroupMissedOut = COALESCE(@GroupMissedOut + ', ', '')
                                  + CONVERT(VARCHAR, MissedOut)
            FROM   #tblfreq
			
			SELECT @GroupPermission = COALESCE(@GroupPermission + ', ', '')
                                  + CONVERT(VARCHAR, Permission)
            FROM   #tblfreq
            DROP TABLE #tblfreq

            SELECT @GroupAchievedHours = Isnull(Sum(worktime), 0)
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @dt
                   AND ddate <= @dt
                   AND worktime IS NOT NULL
                   AND employee_id IN (SELECT employee_id
                                       FROM   employee_master
                                       WHERE  manager_id = @sessionID)

            SELECT @MonthlyGroupAchievedHours = Isnull(Sum(worktime), 0)
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
                   AND ddate <= @lastDay
                   AND worktime IS NOT NULL
                   AND employee_id IN (SELECT employee_id
                                       FROM   employee_master
                                       WHERE  manager_id = @sessionID)

            SELECT @GroupRequiredHours = ( Sum(Datediff(minute, Isnull(in_time1,
                                           '2014-01-01'),
                                                  Isnull(out_time1,
                                           '2014-01-01'))
                                           )
                                           + Sum(Datediff(minute, Isnull(
                                           in_time2
                                           ,
                                           '2014-01-01'),
                                                  Isnull(out_time2,
                                           '2014-01-01'))
                                           )
                                           + Sum(Datediff(minute, Isnull(
                                           in_time3
                                           ,
                                           '2014-01-01'),
                                                  Isnull(out_time3,
                                           '2014-01-01'))
                                           )
                                         )
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @dt
                   AND ddate <= @dt
                   AND restday IS NULL
                   AND employee_id IN (SELECT employee_id
                                       FROM   employee_master
                                       WHERE  manager_id = @sessionID)

            SELECT @MonthlyGroupRequiredHours = (
                   Sum(Datediff(minute, Isnull(in_time1
                   ,
                          '2014-01-01'), Isnull(out_time1
                   ,
                   '2014-01-01')
                          ))
                   + Sum(Datediff(minute, Isnull(in_time2
                   ,
                          '2014-01-01'), Isnull(out_time2
                   ,
                   '2014-01-01')
                          ))
                   + Sum(Datediff(minute, Isnull(in_time3
                   ,
                          '2014-01-01'), Isnull(out_time3
                   ,
                   '2014-01-01')
                          )) )
            FROM   daily_employeeattendancedetails
            WHERE  ddate >= @firstDay
                   AND ddate <= @lastDay
                   AND restday IS NULL
                   AND employee_id IN (SELECT employee_id
                                       FROM   employee_master
                                       WHERE  manager_id = @sessionID)

            DROP TABLE #tbl

            SET @GroupAchievedHoursPercent = CONVERT(INT, ( CONVERT(NUMERIC,
                                                            @GroupAchievedHours)
                                                            /
                                                            CONVERT(NUMERIC,
                                                            @GroupRequiredHours
                                                            )
                                                          ) * 100)
            SET @MonthlyGroupAchievedHoursPercent = (
            CONVERT(NUMERIC, @MonthlyGroupAchievedHours) /
            CONVERT(NUMERIC, @MonthlyGroupRequiredHours
            ) ) * 100

            SELECT dbo.Fn_gettimeformat(Isnull(@GroupAchievedHours, 0))
                   GroupAchievedHours,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyGroupAchievedHours, 0))
                   MonthlyGroupAchievedHours,
                   dbo.Fn_gettimeformat(Isnull(@GroupRequiredHours, 0))
                   GroupRequiredHours,
                   dbo.Fn_gettimeformat(Isnull(@MonthlyGroupRequiredHours, 0))
                   MonthlyGroupRequiredHours,
                   Cast(@GroupAchievedHoursPercent AS NUMERIC(18, 0))
                   GroupAchievedHoursPercent,
                   Cast(@MonthlyGroupAchievedHoursPercent AS NUMERIC(18, 0))
                   MonthlyGroupAchievedHoursPercent,
                   @GroupLate
                   GroupLate,
                   @GroupEarly
                   GroupEarly
                   ,
                   @GroupLeave
                   GroupLeave,
                   @GroupAbsent
                   GroupAbsent,

				   @GroupMissedIn GroupMissedIN,
				   @GroupMissedOut GroupMissedOut,
				   @GroupPermission GroupPermission
				   --'0, 0, 0, 20, 30, 0, 08, 0, 0, 90, 23, 0, 0, 0, 0,77, 0, 8, 90, 0, 43, 0, 30, 0, 0, 80, 0, 0, 55, 0, 0, 30' GroupMissedOut
        END

      IF @action = 'getTrends'
        BEGIN
            --declare @Tmp table (sLate varchar(500),sEarly varchar(500),sLeave varchar(500),sAbsent varchar(500))
            DECLARE @sLate   VARCHAR(500),
                    @sEarly  VARCHAR(500),
                    @sLeave  VARCHAR(500),
                    @sAbsent VARCHAR(500)

            EXEC dbo.[Graph_attnsummary]
              @userID,
              @date,
              NULL,
              NULL,
              NULL,
              @sLate output,
              @sEarly output,
              @sAbsent output,
              @sLeave output

            SELECT @sLate                                [Late],
                   @sEarly                               [Early],
                   @sAbsent                              [Absent],
                   @sLeave                               [Leave],
                   '20,16,23,12,20,16,23,12,20,16,23,12' [Average]
        END

      IF @action = 'getTrendsPercentage'
        BEGIN
            --declare @Tmp table (sLate varchar(500),sEarly varchar(500),sLeave varchar(500),sAbsent varchar(500))
            DECLARE @sLate2   VARCHAR(500),
                    @sEarly2  VARCHAR(500),
                    @sLeave2  VARCHAR(500),
                    @sAbsent2 VARCHAR(500)

            EXEC dbo.[Graph_attnsummary]
              @userID,
              @date,
              NULL,
              NULL,
              NULL,
              @sLate2 output,
              @sEarly2 output,
              @sLeave2 output,
              @sAbsent2 output

            SELECT @sLate2                               [Late],
                   @sEarly2                              [Early],
                   @sAbsent2                             [Absent],
                   @sLeave2                              [Leave],
                --   '20,16,23,12,20,16,23,12,20,16,23,12' 
				'' [Average]
        END

      IF @action = 'getPercentage'
        BEGIN  
			IF EXISTS (SELECT 1 FROM sec_user_roles s, sec_users u where s.user_id = u.user_id	and s.user_id = @userID	and s.role_id != 2)
            BEGIN
					EXEC Dashboard_attndetails
					@userID,
					@dt,
					1,
					@OrganizationID,
					@ManagerID,
					@EmployeeID,
					'ONLOAD',
					'GROUP' 
					 
			END
			ELSE
			BEGIN
				EXEC Dashboard_attndetails
					@userID,
					@dt,
					1,
					@OrganizationID,
					@ManagerID,
					@EmployeeID,
					'ONLOAD',
					'SINGLE'
			END
        --select 10 [LatePercentage], 15 [EarlyPercentage], 5 [AbsentPercentage], 10 [LeavePercentage], 60 [PresentPercentage]
        END

      IF @action = 'getPercentageDepartment'
        BEGIN
            DECLARE @LateCount INT = 0
            DECLARE @TotalWorkingDays INT = 0
            DECLARE @totalorganizationcount INT = 0,
                    @resultSum              INT =0

			select @privilegeID=privilege_id from sec_privileges where privilege_id in (
				SELECT	privilege_id from sec_role_privileges where role_id in (select role_id from sec_user_roles where user_id=@userID)
				) and privilege_name = 'VIEW_ORGANIZATION'
				 
            DECLARE @ParentOrganizationID varchar(max)
			CREATE TABLE #TempOrgTable (OrgID numeric)
			CREATE TABLE #tblEmpID1 (EmpID numeric)
		IF @OrganizationCode = '' AND @OrganizationID = ''
		BeGIN	
				insert into #TempOrgTable exec dbo.sec_get_node_emp_ids @userID, @privilegeID, 1, 'N',1
				insert into #TempOrgTable exec  dbo.sec_get_DeptAdmin_employeeids @SessionID,@PrivilegeId,'N' ,''
		END   
            SELECT @LateCount = (SELECT Count(late)
                                 FROM   daily_employeeattendancedetails
                                 WHERE  Isnull(late, 0) > 0
                                        AND schedule_id > 0)
 
			IF @OrganizationCode  <> '' 
			BEGIN
				
				INSERT INTO #TempOrgTable
				SELECT organization_id FROM   organizations WHERE  code = @OrganizationCode 
			END
			ELSE IF @OrganizationID != ''
			BEGIN 
					INSERT INTO #TempOrgTable
					EXEC USP_GET_ORGANIZATIIONS_HIERARCHY_BY_ORGANIZATIONID @OrganizationID 
			END
			--ELSE
			--BEGIN
			--	INSERT INTO #TempOrgTable
			--	SELECT distinct organization_id 
			--	FROM organizations 
			--	WHERE organization_id != 1 order by 1 asc
			--END
			 
			 INSERT INTO #tblEmpID1 
			 SELECT EMPLOYEE_ID FROM EMPLOYEE_MASTER WHERE ORGANIZATION_ID IN (SELECT ORGID FROM #TempOrgTable)
			 
			IF @ManagerID != '' 
				DELETE #tblEmpID1 WHERE EmpID NOT IN (SELECT distinct employee_id from employee_master where manager_id =  @ManagerID or employee_id  =  @ManagerID)
			 
			IF @EmployeeID != ''
				DELETE #tblEmpID1 WHERE EmpID <> @EmployeeID
			--IF @ManagerID != '' 
			--	DELETE #TempOrgTable WHERE OrgID NOT IN (SELECT distinct Organization_id from employee_master where manager_id =  @ManagerID  and status_flag = 1)
			  
			--IF @EmployeeID != ''
			--	DELETE #TempOrgTable WHERE OrgID NOT IN (SELECT Organization_id from employee_master where employee_id =  @EmployeeID)
		 	
			
			set @ParentOrganizationID = (SELECT  STUFF(( SELECT distinct ',' +  CONVERT(varchar(5),  OrgID)
                FROM #TempOrgTable 
				 WHERE OrgID != 1 order by 1 asc
              FOR
                XML PATH('')
              ), 1, 1, ''))
			   

			  if @type in ('Missed In', 'Missed Out')
			  set @lastDay = GETDATE() - 1

			  if @type = 'Missed In'
				set @type = 'Time_In is Null and Time_Out is not null and ISNULL(ABSENT,0) = 0 and ISNULL(Leave,0) = 0 and ISNULL(Holiday,0) = 0 '
			  else if @type = 'Missed Out'
				set @type = 'Time_In is not Null and Time_Out is  null  and ISNULL(ABSENT,0) = 0 and ISNULL(Leave,0) = 0 and ISNULL(Holiday,0) = 0 '
			  else 
				set @type =  'Isnull(' + @type + ', 0) > 0 '

		            SET @query = N'DECLARE @temptable TABLE
				  (
					 organizationcode       NVARCHAR(100),
					 organizationname       NVARCHAR(max),
					 organizationpercentage float
				  )

			   	INSERT INTO @temptable
				SELECT o.code            OrganizationCode,
					   o.description_eng OrganizationName,
					   CONVERT(decimal(10, 2) ,i.organizationpercentage)
				FROM   (SELECT da.organization_id,
							   Count(*) OrganizationPercentage
						FROM   daily_employeeattendancedetails da
						inner join employee_master em on da.employee_id =  em.employee_id where  em.status_flag = 1 and em.employee_id in (select empid from #tblEmpID1)
						AND  ' + @type  + 
							   ' AND schedule_id > 0 And  Convert(date,ddate,121) >= '''
                         + CONVERT(VARCHAR(11), @firstDay)
                         + ''' AND  Convert(date,ddate,121) <= '''
                         + CONVERT(VARCHAR(11), @lastDay)
                         +'''
						   GROUP  BY da.organization_id) i
					       INNER JOIN organizations o
						  ON i.organization_id = o.organization_id '

							  set @query+='where  o.organization_id in ('+@ParentOrganizationID+');';
			                  set @query+='select OrganizationCode,organizationname, round(((organizationpercentage/(select sum(organizationpercentage) from @temptable))*100),2) organizationpercentage from @temptable'

PRINT( @query )

EXEC(@query)

RETURN;
END
 

    IF @action = 'getDepartmentViolationDetails'
      BEGIN
	  SET @searchInput = '''%' + @searchInput + '%''';
          CREATE TABLE #tblorgid
            (
               orgid NUMERIC
            )

			CREATE TABLE #tblEmpID (EmpID numeric)
			 
			IF @OrganizationCode  <> '' AND @OrganizationCode != 'undefined' 
			BEGIN
				INSERT INTO #tblorgid
				SELECT organization_id FROM   organizations WHERE  code = @OrganizationCode 
			END
			ELSE IF @OrganizationID != ''
			BEGIN 
					INSERT INTO #tblorgid
					EXEC USP_GET_ORGANIZATIIONS_HIERARCHY_BY_ORGANIZATIONID @OrganizationID 
			END
			ELSE
			BEGIN
				INSERT INTO #tblorgid
				SELECT distinct organization_id 
				FROM organizations 
				WHERE organization_id != 1 order by 1 asc
			END
			 
			 
			 INSERT INTO #tblEmpID 
			 SELECT EMPLOYEE_ID FROM EMPLOYEE_MASTER WHERE ORGANIZATION_ID IN (SELECT ORGID FROM #tblorgid) and status_flag = 1
			
			
			IF(ISNULL(@OrganizationID,'') != '' OR ISNULL(@OrganizationCode,'')  <> '' )
				DELETE FROM #tblEmpID WHERE EmpID  not in (select employee_id from employee_master where organization_id IN (select OrgID from #tblorgid)) 

			IF @ManagerID != '' 
				DELETE #tblEmpID WHERE EmpID NOT IN (SELECT distinct employee_id from employee_master where manager_id =  @ManagerID or employee_id  =  @ManagerID)
			 
			IF @EmployeeID != ''
				DELETE #tblEmpID WHERE EmpID <> @EmployeeID
		 	  
          DECLARE @list NVARCHAR(max)

          SET @list = (SELECT Stuff((SELECT DISTINCT ',' + CONVERT(VARCHAR(5),
                                                     EmpID
                                                     )
             FROM   #tblEmpID
                                     ORDER  BY 1 ASC
                                     FOR xml path('')), 1, 1, '') AS
                              OrganizationList)
          SET @query =N'select * from (select  ROW_NUMBER() OVER (  order by '
                      + @orderBy
                      +
' ) AS RowNum, employee_code [EmployeeCode],EmployeeNameEng name_eng,EmployeeNameArb name_arb,
		ddate [Date], '

		--Added By Wajahat To Consider only late data on the drill down for current day [add type if further required type is requested / or change the logic]
		 
		     if @type in ('Missed Out')  and Convert(nvarchar(10),@lastDay,121) =  CONVERT(nvarchar(10),GETDATE(),121)
			    set @lastDay = CONVERT(nvarchar(10),GETDATE()-1,121)

			  ----END --- 
			   

		if @type = 'Missed In'
		  begin
		    set @query += 'Time_Out as Time_IN,ActualSchInPerMove as SchIn,';
			set @query += '''Missed In'' as [' + @type +']'
			 set @type = 'Time_In is Null and Time_Out is not null and absent is null 
							AND ISNULL(LEAVE,0) = 0
							AND ISNULL(restday,0) = 0
							AND ISNULL(holiday,0) = 0'

		  end 
 		else if @type = 'Missed Out'
		  begin
		   set @query += 'Time_IN,ActualSchOutPerMove as SchIn,';
			set @query += '''Missed Out'' as [' + @type +']' 
			 set @type = 'Time_In is not Null and Time_Out is  null  and absent is null
							AND ISNULL(LEAVE,0) = 0
							AND ISNULL(restday,0) = 0
							AND ISNULL(holiday,0) = 0'
		   end
		else if @type ='early' 
		BEGIN
		   set @query += 'Time_Out as Time_IN ,ActualSchOutPerMove as SchIn,';
		   set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		   set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END
		else if @type ='late' 
		BEGIN
		   set @query += 'Time_IN,ActualSchInPerMove as SchIn,';
		   set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		    set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END
		else if @type ='leave' 
		BEGIN
		   set @query += 'ActualSchInPerMove as SchIn,Remarks as ' + @type
		   --set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		    set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END
		else if @type = 'absent'
		BEGIN
		   set @query += 'ActualSchInPerMove as SchIn,comment as ' + @type
		 --  set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		    set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END 
	
		 set @query += '
		from daily_EmployeeAttendanceDetails 
		Where '
            + @type
            + '    and employee_id  IN ('
            + @list
            + ') And  Convert(date,ddate,121) >= '''
            + CONVERT(varchar, @firstDay)
            + ''' and Convert(date,ddate,121) <= '''
            + CONVERT(varchar, @lastDay)
            + ''' 
			and 
				(
					employee_code Like '+@searchInput+' or EmployeeNameEng like '+@searchInput+' or EmployeeNameArb like '+@searchInput+') 
			
			 ) AS RowConstrainedResult
										WHERE   RowNum > ' + @startRow
            + ' AND RowNum <= ' + @endRow + ''
    PRINT( @query )

    EXEC(@query)

    DROP TABLE #tblorgid
	DROP TABLE #tblEmpID
    RETURN;
END

    IF @action = 'getDepartmentViolationCount'
      BEGIN
	    SET @searchInput = '''%' + @searchInput + '%''';
          CREATE TABLE #tblaorgid
            (
               orgid NUMERIC
            )
			CREATE TABLE #tblEmpID2 (EmpID numeric)
			 
          
			IF @OrganizationCode  <> '' AND @OrganizationCode != 'undefined' 
			BEGIN
				INSERT INTO #tblaorgid
				SELECT organization_id FROM   organizations WHERE  code = @OrganizationCode 
			END
			ELSE IF @OrganizationID != ''
			BEGIN 
					INSERT INTO #tblaorgid
					EXEC USP_GET_ORGANIZATIIONS_HIERARCHY_BY_ORGANIZATIONID @OrganizationID 
			END
			ELSE
			BEGIN
				INSERT INTO #tblaorgid
				SELECT distinct organization_id 
				FROM organizations 
				WHERE organization_id != 1 order by 1 asc
			END

			 INSERT INTO #tblEmpID2 
			 SELECT EMPLOYEE_ID FROM EMPLOYEE_MASTER WHERE ORGANIZATION_ID IN (SELECT ORGID FROM #tblaorgid) and status_flag = 1
			
			
			IF(ISNULL(@OrganizationID,'') != '' OR ISNULL(@OrganizationCode,'')  <> '' )
				DELETE FROM #tblEmpID2 WHERE EmpID  not in (select employee_id from employee_master where organization_id IN (select OrgID from #tblaorgid)) 

			IF @ManagerID != '' 
				DELETE #tblEmpID2 WHERE EmpID NOT IN (SELECT distinct employee_id from employee_master where manager_id =  @ManagerID or employee_id  =  @ManagerID)
			 
			IF @EmployeeID != ''
				DELETE #tblEmpID2 WHERE EmpID <> @EmployeeID
			 
		 	

          DECLARE @listCount NVARCHAR(max)

          SET @listCount = (SELECT Stuff((SELECT DISTINCT ',' + CONVERT(VARCHAR(5),
                                                     EmpID
                                                     )
                                     FROM   #tblEmpID2
                                     ORDER  BY 1 ASC
                                     FOR xml path('')), 1, 1, '') AS
                              OrganizationList)
          SET @query =N'select Count(*) '

		 if @type in ('Missed Out')  and Convert(nvarchar(10),@lastDay,121) =  CONVERT(nvarchar(10),GETDATE(),121)
			 set @lastDay = CONVERT(nvarchar(10),GETDATE()-1,121)

		if @type = 'Missed In'
		  begin
		   -- set @query += 'Time_out,Time_IN,ActualSchInPerMove as SchIn,';
			--set @query += '''Missed In'' as [' + @type +']'
			 set @type = 'Time_In is Null and Time_Out is not null and absent is null
							AND ISNULL(LEAVE,0) = 0
							AND ISNULL(restday,0) = 0
							AND ISNULL(holiday,0) = 0'

		  end 
 		else if @type = 'Missed Out'
		  begin
		   --set @query += 'Time_IN,ActualSchOutPerMove as SchIn,';
			--set @query += '''Missed Out'' as [' + @type +']' 
			 set @type = 'Time_In is not Null and Time_Out is  null  and absent is null
					      AND ISNULL(LEAVE,0) = 0
					      AND ISNULL(restday,0) = 0
					      AND ISNULL(holiday,0) = 0'
		   end
		else if @type ='early' 
		BEGIN
		   --set @query += 'Time_Out as Time_IN ,ActualSchOutPerMove as SchIn,';
		   --set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		   set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END
		else if @type ='late' 
		BEGIN
		   --set @query += 'Time_IN,ActualSchInPerMove as SchIn,';
		   --set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		    set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END
		else if @type ='leave' 
		BEGIN
		   --set @query += 'Remarks as ' + @type
		   --set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		    set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END
		else if @type = 'absent'
		BEGIN
		   --set @query += 'comment as ' + @type
		 --  set @query += 'dbo.fn_GetTimeFormat(IsNull('+ @type + ', 0)) as ' + @type 
		    set @type  = ' IsNull('+ @type + ', 0) > 0 '
		END 

		 set @query += '
		from daily_EmployeeAttendanceDetails 
		Where '
            + @type
            + '    and employee_id  IN ('
            + @listCount
            + ') And  Convert(date,ddate,121) >= '''
            + CONVERT(varchar, @firstDay)
            + ''' and Convert(date,ddate,121) <= '''
            + CONVERT(varchar, @lastDay)
            + ''' 
			and 
				(
					employee_code Like '+@searchInput+' or EmployeeNameEng like '+@searchInput+' or EmployeeNameArb like '+@searchInput+')'	
					 
    PRINT( @query )

    EXEC(@query)
			
	 
    DROP TABLE #tblaorgid
    DROP TABLE #tblEmpID2

          RETURN;
      END

    IF @action = 'getMyLateDetails'
      BEGIN
          IF @startRow = ''
            SET @startRow = 0

          IF @endRow = ''
            SET @endRow = 10

          EXEC Dashboard_attndetails
            @userID,
            @dt,
   1,
            @OrganizationID,
			@ManagerID,
            @EmployeeID,
            'ONCLICK',
            @scope,
            @type,
            @searchInput,
            @orderBy,
            @startRow,
            @endRow,
            'records'

          RETURN;
      END

    IF @action = 'getMyLateDetailsCount'
      BEGIN 

          IF @startRow = ''
            SET @startRow = 0

          IF @endRow = ''
            SET @endRow = 10

           EXEC Dashboard_attndetails
            @userID,
            @dt,
            1,
            @OrganizationID,
			@ManagerID,
            @EmployeeID,
            'ONCLICK',
            @scope,
            @type,
            @searchInput,
            @orderBy,
            @startRow,
            @endRow,
            'count'

          RETURN;
      END

    IF @action = 'getMyAbsentDetails'
      BEGIN
          IF @startRow = ''
            SET @startRow = 0

          IF @endRow = ''
            SET @endRow = 10

          CREATE TABLE #tbllate3
            (
               employee_code VARCHAR(50),
               name_eng      VARCHAR(200),
               name_arb      NVARCHAR(200),
               ddate         DATETIME,
               punch         DATETIME,
               sch           DATETIME,
               late_early    INT
            )

          INSERT INTO #tbllate3
          EXEC Dashboard_attndetails
            @userID,
            @dt,
            NULL,
            NULL,
            NULL,
            'ONCLICK',
            @scope,
            @type

          SET @endRow = CONVERT(NUMERIC, @startRow)
                        + CONVERT(NUMERIC, @endRow);
          SET @searchInput = '''%' + @searchInput + '%''';
          SET @query = 'SELECT  * FROM     
		( SELECT    ROW_NUMBER() OVER (  order by '
                       + @orderBy + ' ) AS RowNum, employee_code, name_eng, name_arb, Ddate, sch, punch, dbo.fn_GetTimeFormat(IsNull(late_early, 0)) late_early FROM  #tblLate3 
		Where 
		employee_code Like '
                       + @searchInput + ' or name_eng Like '
                       + @searchInput + ' or  
		name_arb Like '
                       + @searchInput + ' or sch Like ' + @searchInput
                       + '  or  
		punch Like ' + @searchInput
                       + ' or late_early Like ' + @searchInput
                       + ' ) AS RowConstrainedResult
		WHERE   RowNum > ' + @startRow
                       + ' AND RowNum <= ' + @endRow;

          EXEC(@query);

          DROP TABLE #tbllate3

          RETURN;
      END

    IF @action = 'GetAttendanceActivity'
    BEGIN
    create table #tblEmp(EmpId numeric(18,0))
	 select @privilegeID=privilege_id from sec_privileges where privilege_id in (
		SELECT	privilege_id from sec_role_privileges where role_id in (select role_id from sec_user_roles where [user_id]=@userID)
		) and privilege_name = 'VIEW_EMPLOYEE'

		insert into #tblEmp exec dbo.sec_get_node_emp_ids @userID, @privilegeID, 0, 'E' , 1
		 
		  SELECT 
		   vea.Transaction_Id,
		   vea.Transaction_Time,  
	       CONVERT(varchar(10),  vea.Transaction_Time,121) AS Ddate,
		   Employee_Id,
	       case when @IsArabic = '1' then vea.name_arb else vea.name_eng end EmployeeName,
		   vea.ReasonId,
		   case when @IsArabic = '1' then vea.Reason_Arb else vea.Reason_Eng end Reason,
		   vea.ReasonMode
           from Vw_EmployeeActivity vea 
		   where 
		   vea.Employee_Id in (select empId from #tblEmp)
		   and
		   CONVERT(varchar(19), vea.Transaction_Time,121) > CONVERT(varchar(19), @activityLastTransactionTime,121)
	  drop table #tblEmp

    RETURN;
    END

	IF @action = 'GetReaderTransactionsCount'
	begin
		
		--IF EXISTS(SELECT 1 from employee_event_transactions evt, readers rdr where	evt.reader_id = rdr.reader_id and CONVERT(nvarchar(10),transaction_time,121) = @dt )
		--BEGIN
			select  rdr.reader_name + '  (Transactions = ' + CONVERT(nvarchar(100),Count(*)) + ')' reader_Name , 
			(CASE WHEN evt.reader_location is not null then evt.reader_location else rdr.reader_location end) reader_location
			from employee_event_transactions evt, readers rdr
			where
			evt.reader_id = rdr.reader_id
			and CONVERT(nvarchar(10),transaction_time,121) = @dt 
			group by  CONVERT(nvarchar(10),transaction_time,121),evt.reader_location  , rdr.reader_name ,rdr.reader_location
			UNION
			SELECT  reader_name + '  (Transactions = 0)' reader_Name ,reader_location  reader_location
			FROM readers
			WHERE 
			reader_id not in (select distinct reader_id from employee_event_transactions where CONVERT(nvarchar(10),Transaction_Time,121) = @dt)
		--END
		--ELSE
		--BEGIN 
		--	select  rdr.reader_name + '  (Transactions = 0)' reader_Name , rdr.reader_location  reader_location
		--	from   readers rdr  

		--END
	end
---------------------------------------------------------------------
---------------- GET My Daily Time Attendance -----------------------
---------------------------------------------------------------------


if @action  = 'GetTeamYearlyStatisticByMemberId'
	BEGIN

	  declare @month  int =  1
	   declare @year int = convert(int,@date)
	    
	   declare @fromDate nvarchar(10)  
	   declare @datemonth nvarchar(2)
	   create table #wholeyearattendance
	   (
	      [Month] int ,
		  [MonthName] nvarchar(200),
		  [Late] int,
		  [Early] int,
		  [Absent] int,
		  [Leaves] int,
		  [MissedIN] int,
		  [MissedOut] int,
		  [Year] int
	   )
	   
	   declare  @late_count int,@early_count int,@absent_Count int, @leave_count int, @MissedIn_Count int, @MissedOut_Count int
	   while @month <=12
	   BEGIN
	       
		   if @month < 10
		     set @datemonth =  '0' + convert(varchar, @month)
			 else
			 set @datemonth = convert(varchar, @month)

		   set @fromDate =  CONVERT(varchar , @year)+ '-' + @datemonth + '-01'


		   set @ToDate = CONVERT(varchar(10), DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@fromDate)+1,0)),121)

		   print @fromDate
		   print @toDate
		   
	      select @late_count = count(late) from daily_EmployeeAttendanceDetails  where Ddate >= @fromDate and Ddate <= @ToDate and employee_id  = @MemberId and (ISNULL(late,0) > 0 )    group by employee_id
		  select @early_count = count(early) from daily_EmployeeAttendanceDetails  where   Ddate between @fromDate and @ToDate and employee_id  = @MemberId  and (ISNULL(early,0) > 0)  group by employee_id
		  select @absent_Count = count([absent]) from daily_EmployeeAttendanceDetails  where  Ddate between @fromDate and @ToDate and  employee_id  = @MemberId and (ISNULL([absent],0) > 0)   group by employee_id
		  select @leave_count = count(leave) from daily_EmployeeAttendanceDetails  where Ddate between @fromDate and @ToDate and employee_id  = @MemberId   and (ISNULL(leave,0) > 0 )   group by employee_id
		  select @MissedIn_Count = count(*) from daily_EmployeeAttendanceDetails  
		  where 
					Ddate between @fromDate and @ToDate and employee_id  = @MemberId  and (Time_In IS NULL AND Time_Out IS NOT NULL )
			and	    ISNULL(holiday,0) = 0  AND ISNULL(leave,0) = 0 AND ISNULL(restday,0) = 0 
		  group by	employee_id

		  select @MissedOut_Count = count(*) from daily_EmployeeAttendanceDetails  
		  where 
					Ddate between @fromDate and @ToDate and employee_id  = @MemberId  and (Time_In IS NOT NULL AND Time_Out IS NULL )
			and	    ISNULL(holiday,0) = 0  AND ISNULL(leave,0) = 0 AND ISNULL(restday,0) = 0 
		 group by employee_id
		 

		  insert into #wholeyearattendance([Month],[MonthName] , Late ,Early,[Absent],Leaves,MissedIN,MissedOut,[Year])
		  select @month, DateName(mm,DATEADD(mm,@month,-1)), ISNULL(@late_count,0),isnull(@early_count,0),isnull(@absent_Count,0),isnull(@leave_count,0),isnull(@MissedIn_Count,0),isnull(@MissedOut_Count,0),@year

		  set @month =  @month + 1

		  
		  set @early_count = 0
		  set @late_count = 0
		  set @absent_Count = 0 
		  set @leave_count = 0
		  set @MissedIn_Count = 0
		  set @MissedOut_Count = 0
	   END
	   select * from #wholeyearattendance
	   drop table #wholeyearattendance
	END


DROP TABLE #copyOrgID
END
 


