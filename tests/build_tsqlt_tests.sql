/************************************
Begin sp_sizeoptimiser tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'testsizeoptimiser';
GO

EXEC tSQLT.NewTestClass 'testsizeoptimiser';
GO

/*
test that sp_sizeoptimiser exists
*/
CREATE PROCEDURE testsizeoptimiser.[test sp_sizeoptimiser exists]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_sizeoptimiser', @message = 'Stored procedure sp_sizeoptimiser does not exist.';

END;
GO

/*
test that SizeOptimiserTableType exists
*/
CREATE PROCEDURE testsizeoptimiser.[test sp_sizeoptimisertabletype exists]
AS
BEGIN

DECLARE @actual BIT = 0;
DECLARE @expected BIT = 1;

--Check for table type 
SELECT @actual = 1
FROM sys.table_types
WHERE [name] = 'SizeOptimiserTableType'

--Assert
EXEC tSQLt.AssertEquals @expected, @actual, @message = 'User defined table type SizeOptimiserTableType does not exist';

END;
GO

/*
test that incorrect @IndexNumThreshold throws error 
*/
CREATE PROCEDURE testsizeoptimiser.[test incorrect @IndexNumThreshold throws error]
AS
BEGIN

--Assert
EXEC tSQLt.ExpectException @ExpectedMessage = N'@IndexNumThreshold must be between 1 and 999.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC dbo.sp_sizeoptimiser @IndexNumThreshold = 0

END;
GO

/* test result set has correct table schema*/
CREATE PROCEDURE testsizeoptimiser.[test result set metadata is correct]
AS
BEGIN

DECLARE @version NVARCHAR(MAX) = @@VERSION

--AssetResulteSets breaks for SQL 2008 R2
IF (@version NOT LIKE '%2008 R2%')
BEGIN
	EXEC tSQLt.AssertResultSetsHaveSameMetaData 
		@expectedCommand = N'CREATE TABLE #results
							([check_num]	INT NOT NULL,
							[check_type]	NVARCHAR(50) NOT NULL,
							[db_name]		SYSNAME NOT NULL,
							[obj_type]		SYSNAME NOT NULL,
							[obj_name]		SYSNAME NOT NULL,
							[col_name]		SYSNAME NULL,
							[message]		NVARCHAR(500) NULL,
							[ref_link]		NVARCHAR(500) NULL);  
							SELECT * FROM #results;',
		@actualCommand = N'EXEC dbo.sp_sizeoptimiser;'
END

END;
GO

/*
test that passing @IncludeDatabases 
and @ExcludeDatabases fails
*/
CREATE PROCEDURE testsizeoptimiser.[test using include and exclude throws error]
AS
BEGIN

--Build
DECLARE @IncludeDatabases [dbo].[SizeOptimiserTableType]; 
DECLARE @ExcludeDatabases [dbo].[SizeOptimiserTableType]; 

INSERT INTO @INcludeDatabases
VALUES ('master');

INSERT INTO @ExcludeDatabases
VALUES ('model');

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'Both @IncludeDatabases and @ExcludeDatabases cannot be specified.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 50000
EXEC [dbo].[sp_sizeoptimiser] NULL, @IncludeDatabases = @IncludeDatabases, @ExcludeDatabases = @ExcludeDatabases;

END;
GO

/************************************
End sp_sizeoptimiser tests
*************************************/

/************************************
Begin sp_helpme tests
*************************************/

--Clean Class
EXEC tSQLt.DropClass 'testsphelpme';
GO

EXEC tSQLT.NewTestClass 'testsphelpme';
GO

/*
test that sp_sizeoptimiser exists
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme exists]
AS
BEGIN

--Assert
EXEC tSQLt.AssertObjectExists @objectName = 'dbo.sp_helpme', @message = 'Stored procedure sp_helpme does not exist.';

END;
GO

/*
test that sp_helpme errors on non-existant object
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme errors for missing object]
AS
BEGIN

--Build
DECLARE @Table SYSNAME = 'dbo.IDontExist';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''';';

--Assert
EXEC [tSQLt].[ExpectException] @ExpectedMessage = N'The object ''dbo.IDontExist'' does not exist in database ''tSQLt'' or is invalid for this operation.', @ExpectedSeverity = 16, @ExpectedState = 1, @ExpectedErrorNumber = 15009
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/*
test that sp_helpme does not fail for object that exists
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme does not error for object that exists]
AS
BEGIN

--Build
--Assume tSQLt's table tSQLt.CaptureOutputLog always exists
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''';';

--Assert
EXEC tSQLt.ExpectNoException;
EXEC tSQLt.ResultSetFilter 0, @cmd; --Still runs but suppresses undesired output

END;
GO

/*
test first result set of sp_helpme for a table
*/
CREATE PROCEDURE testsphelpme.[test sp_helpme first result for table]
AS
BEGIN

--Build
--Assume tSQLt's table tSQLt.CaptureOutputLog always exists
DECLARE @Table SYSNAME = 'tSQLt.CaptureOutputLog';
DECLARE @epname SYSNAME = 'Description';
DECLARE @cmd NVARCHAR(MAX) = N'EXEC [sp_helpme] ''' + @Table + ''', ''' + @epname + ''';';

CREATE TABLE #Expected  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)

INSERT INTO #Expected
SELECT
	[Name]					= o.name,
	[Owner]					= user_name(ObjectProperty(object_id, 'ownerid')),
	[Type]					= substring(v.name,5,31),
	[Created_datetime]		= o.create_date,
	[Modify_datetime]		= o.modify_date,
	[ExtendedProperty]		= ep.[value]
FROM sys.all_objects o
	INNER JOIN master.dbo.spt_values v ON o.type = substring(v.name,1,2) collate DATABASE_DEFAULT
	LEFT JOIN sys.extended_properties ep ON ep.major_id = o.[object_id]
		AND ep.[name] = @epname
		AND ep.minor_id = 0
		AND ep.class = 1 
WHERE v.type = 'O9T'
	AND o.name = 'CaptureOutputLog';

CREATE TABLE #Actual  (
	[name] SYSNAME NOT NULL
	,[owner] NVARCHAR(20) NOT NULL
	,[object_type] NVARCHAR(100) NOT NULL
	,[create_datetime] DATETIME NOT NULL
	,[modify_datetime] DATETIME NOT NULL
	,[ExtendedProperty] SQL_VARIANT NULL
)
INSERT INTO #Actual
EXEC tSQLt.ResultSetFilter 1, @cmd;

--Assert
EXEC tSQLt.AssertEqualsTable #Expected, #Actual;

END;
GO

/************************************
End sp_helpme tests
*************************************/