USE $(Database)
GO

--while running sql only script, please replace these values:
----$(Database),$(schema)

--one time set up file to create functions and stored procedures to hash demographic table

--hash and salt function type 2
IF OBJECT_ID(N'$(schema).fnHashBytes2', N'FN') IS NOT NULL
BEGIN
   DROP FUNCTION $(schema).fnHashBytes2
END
GO

CREATE FUNCTION [$(schema)].[fnHashBytes2] (@DataToHash VARCHAR(MAX), @Salted VARCHAR(30))
RETURNS VARCHAR(128)
AS
BEGIN
    DECLARE @HashedResult VARCHAR(128)
    IF @DataToHash IS NOT NULL
       BEGIN
            SET @HashedResult = CONVERT(VARCHAR(128), HASHBYTES('SHA2_512', @DataToHash+@Salted), 2)
       END
       RETURN @HashedResult
END
GO

--remove double space and hyphen
IF OBJECT_ID(N'$(schema).stripDoubleSpaces', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).stripDoubleSpaces
END
GO

CREATE FUNCTION [$(schema)].[stripDoubleSpaces](@prmSource VARCHAR(100)) 
RETURNS VARCHAR(100)
AS 
BEGIN
SET @prmSource=LTRIM(RTRIM(@prmSource)) --remove pre-and trailing spaces
	DECLARE @keepValues AS VARCHAR(50)
    SET @keepValues = '%[-]%'
    WHILE PATINDEX(@keepValues, @prmSource)>0
        SET @prmSource = STUFF(@prmSource, PATINDEX(@keepValues, @prmSource), 1, ' ') 
	WHILE (PATINDEX('%  %', @prmSource)>0)
        SET @prmSource = STUFF(@prmSource, PATINDEX('%  %', @prmSource), 1, '') 
		--@prmSource = replace(@prmSource  ,'  ',' ')
    RETURN REPLACE(@prmSource,'  ',' ')
END
GO

--keep alphabets, space and hyphens only
IF OBJECT_ID(N'$(schema).fnAlHySpOnly', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).fnAlHySpOnly
END
GO

CREATE FUNCTION [$(schema)].[fnAlHySpOnly](@string VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
    WHILE PATINDEX('%[^A-Z -]%', @string) > 0
	      SET @string = STUFF(@string, PATINDEX('%[^A-Z -]%', @string), 1, '')--('%[^A-Z ''^-]%'
	WHILE charindex('  ',@string  ) > 0
		  SET @string = replace(@string, '  ', ' ')
	WHILE charindex('--',@string  ) > 0
		  SET @string = replace(@string, '--', '-')
RETURN LTRIM(RTRIM(@string))
END
GO

--keep alphabets only
IF OBJECT_ID(N'$(schema).fnAlphaOnly', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).fnAlphaOnly
END
GO

CREATE FUNCTION [$(schema)].[fnAlphaOnly](@string VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
    WHILE PATINDEX('%[^A-Z]%', @string) > 0
	      SET @string = STUFF(@string, PATINDEX('%[^A-Z]%', @string), 1, '')
RETURN @string
END
GO

--keep numbers only
IF OBJECT_ID(N'$(schema).fnNumberOnly', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).fnNumberOnly
END
GO

CREATE FUNCTION [$(schema)].[fnNumberOnly](@string VARCHAR(30))
RETURNS VARCHAR(30)
AS
BEGIN
DECLARE @stringint INT
	SET @stringint = PATINDEX('%[^0-9]%', @string)
	BEGIN
		WHILE @stringint > 0
		BEGIN
			SET @string = STUFF(@string, @stringint, 1, '' )
			SET @stringint = PATINDEX('%[^0-9]%', @string )
		END
	END
RETURN RIGHT(ISNULL(@string,0),4)
END
GO

--remove commonly known prefixes
IF OBJECT_ID(N'$(schema).fnRemovePrefix2', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).fnRemovePrefix2
END
GO

CREATE FUNCTION [$(schema)].[fnRemovePrefix2](@Name VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
	SET @Name=UPPER(LTRIM(RTRIM([$(schema)].[stripDoubleSpaces](@Name))))
	SET @Name = CASE WHEN LEN(@Name)>4 AND LEFT(@Name,5) IN ('MISS ','MRS. ','MISS-','MRS.-' ) THEN RIGHT(@Name, LEN(@Name) - 5)
					 WHEN LEN(@Name)>3 AND LEFT(@Name,4) IN ('MRS ', 'MR. ', 'MS. ', 'DR. ','MRS-', 'MR.-', 'MS.-', 'DR.-') THEN RIGHT(@Name, LEN(@Name) - 4)
					 WHEN LEN(@Name)>2 AND LEFT(@Name,3) IN ('MR ', 'MS ', 'DR ','MR-', 'MS-', 'DR-') THEN RIGHT(@Name, LEN(@Name) - 3)
				 ELSE (@Name) 
				 END
RETURN (@Name)
END
GO

--remove commonly known suffixes
IF OBJECT_ID(N'$(schema).fnRemoveSuffix2', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).fnRemoveSuffix2
END
GO

CREATE FUNCTION [$(schema)].[fnRemoveSuffix2](@Name VARCHAR(100))
RETURNS VARCHAR(100)
BEGIN
	SET @Name = CASE WHEN LEN(@Name)>4 AND RIGHT(@Name,4) IN (' III',' 1ST',' 2ND',' 3RD',' JR.',' SR.','-III','-1ST','-2ND','-3RD','-JR.','-SR.') THEN [$(schema)].[fnAlHySpOnly](LEFT(@Name, LEN(@Name) - 4))
					 WHEN LEN(@Name)>3 AND RIGHT(@Name,3) IN (' II',' IV',' VI',' JR',' SR',' MA',' MD','-II','-IV','-VI','-JR','-SR','-MA','-MD')	THEN [$(schema)].[fnAlHySpOnly](LEFT(@Name, LEN(@Name) - 3))
					 WHEN LEN(@Name)>2 AND RIGHT(@name,2) IN (' I',' V','-I','-V')	THEN [$(schema)].[fnAlHySpOnly](LEFT(@Name, LEN(@Name) - 2))
				 ELSE [$(schema)].[fnAlHySpOnly](@Name) 
				 END
RETURN (@Name)
END
GO

--format date
IF OBJECT_ID(N'$(schema).fnFormatDate', N'FN') IS NOT NULL
BEGIN
  DROP FUNCTION $(schema).fnFormatDate
END
GO

CREATE FUNCTION [$(schema)].[fnFormatDate] (@Datetime DATETIME, @FormatMask VARCHAR(32))
RETURNS VARCHAR(32)
AS
BEGIN
    DECLARE @StringDate VARCHAR(32)
    SET @StringDate = @FormatMask
    IF (CHARINDEX ('YYYY',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'YYYY',
                         DATENAME(YY, @Datetime))

    IF (CHARINDEX ('YY',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'YY',
                         RIGHT(DATENAME(YY, @Datetime),2))

    IF (CHARINDEX ('Month',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'Month',
                         DATENAME(MM, @Datetime))

    IF (CHARINDEX ('MON',@StringDate COLLATE SQL_Latin1_General_CP1_CS_AS)>0)
       SET @StringDate = REPLACE(@StringDate, 'MON',
                         LEFT(UPPER(DATENAME(MM, @Datetime)),3))

    IF (CHARINDEX ('Mon',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'Mon',
                                     LEFT(DATENAME(MM, @Datetime),3))

    IF (CHARINDEX ('MM',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'MM',
                  RIGHT('0'+CONVERT(VARCHAR,DATEPART(MM, @Datetime)),2))

    IF (CHARINDEX ('M',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'M',
                         CONVERT(VARCHAR,DATEPART(MM, @Datetime)))

    IF (CHARINDEX ('DD',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'DD',
                         RIGHT('0'+DATENAME(DD, @Datetime),2))

    IF (CHARINDEX ('D',@StringDate) > 0)
       SET @StringDate = REPLACE(@StringDate, 'D',
                                     DATENAME(DD, @Datetime))   

RETURN @StringDate
END
GO
