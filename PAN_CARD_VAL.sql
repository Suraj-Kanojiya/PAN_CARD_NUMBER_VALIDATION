
--Invalid object name occurs when SQL Server cannot find the object in the current database or schema. 
--Using the fully qualified name or mentioning the database resolves it
USE PANCARD; 
GO

--PAN Number Validation Project--
Select * from PANNumberData;

Alter table PANNumberData Alter Column Pan_numbers varchar(50);

--check for duplicates
Select Pan_Numbers, count(1)
from PANNumberData
GROUP BY Pan_Numbers
having count(1)>1;

--handling leading/trailing spaces
select * from PANNumberData where Pan_Numbers <> Trim(Pan_Numbers);

--Need only uppercase letter-- This query does not work in MSSQL because of SQL Server collation 
--By default, MSSQL uses a case-insensitive collation,
--Select * from PANNumberData where Pan_numbers <> upper(Pan_Numbers);

SELECT *
FROM PANNumberData
WHERE Pan_numbers <> UPPER(Pan_numbers) COLLATE Latin1_General_CS_AS;

--Cleaned PAN Number
Select Distinct Pan_Numbers from  PANNumberData

--Cleaned pan numbers + All letters in uppercase
Select Distinct UPPER(Pan_numbers) from  PANNumberData

--Function to check if the adjacent characters are same
--SQL Server uses WHILE loops and BIT return types for procedural logic inside scalar functions.
--SQL Server does not support FOR i IN, LOOP, BOOLEAN, or TRUE/FALSE like this.
/*CREATE FUNCTION adj_char (@pstr varchar(50))
RETURNS boolean
AS 
BEGIN
    For i in 1....length(@pstr)
	loop
	  if substring(@pstr, i,1)=substring(@pstr, i+1,1)
	  then
	     return true; --adjacent characters same
      end if;
	end loop;
	return false; non of the adjac characters were same
end;*/

Create Function adjCharSame(@pstr Varchar(50))
Returns BIT
AS 
Begin
   Declare @i int=1;
   Declare @len INT = LEN(@pstr);

   While @i<@len 
   Begin
      if  SUBSTRING(@pstr, @i,1)=SUBSTRING(@pstr, @i+1,1)
	  Begin
		  return 1; -- Adj characters same
      END;
	  SET @i=@i+1;
   END;
   Return 0; -- Adj Characters not same
END;
GO 


--test for same adjacent characters
Select adjCharSame('JACHK4574O')


CREATE FUNCTION dbo.adjCharSEQ (@pstr VARCHAR(50))
RETURNS BIT
AS
BEGIN
    DECLARE @i INT = 1;
    DECLARE @len INT = LEN(@pstr);

    WHILE @i < @len
    BEGIN
        -- If any adjacent characters are NOT sequential
        IF ASCII(SUBSTRING(@pstr, @i + 1, 1))
           - ASCII(SUBSTRING(@pstr, @i, 1)) <> 1
        BEGIN
            RETURN 0;  -- NOT fully sequential
        END;

        SET @i = @i + 1;
    END;

    RETURN 1;  -- FULLY sequential
END;
GO
--check for character sequence
Select dbo.adjCharSEQ('ACZSE2856I');

--Regular expression to validate the pattern of PAN Numbers
Select * from PANNumberData
where Pan_Numbers like '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]';


create view validinvalid
as 
With cleanedPAN as (
   Select DISTINCT UPPER(Pan_numbers) as  Pan_Numbers from  PANNumberData
   ),
    ValidPAN as
    (Select * from cleanedPAN
    where dbo.adjCharSame(Pan_Numbers)=0
    AND dbo.adjCharSEQ(SUBSTRING(Pan_Numbers,1,5))=0
	AND dbo.adjCharSEQ(SUBSTRING(Pan_Numbers,6,4))=0
    AND Pan_Numbers like '[A-Z][A-Z][A-Z][A-Z][A-Z][0-9][0-9][0-9][0-9][A-Z]')

Select cln.Pan_numbers,
case when vld.Pan_numbers is not NULL 
then 'VALID PAN' 
else 'INVALID PAN' 
end as Status
from CleanedPAN cln
left join ValidPAN vld on cln.Pan_numbers=vld.Pan_numbers;

With report as 
	(SELECT
    (Select count(*) from PANNumberData) as total_processed_records,
    COUNT(CASE WHEN status = 'VALID PAN' THEN 1 END)   AS total_valid_pans,
    COUNT(CASE WHEN status = 'INVALID PAN' THEN 1 END) AS total_invalid_pans
	FROM validinvalid)
Select total_processed_records,total_valid_pans,total_invalid_pans,
(total_processed_records-(total_valid_pans+total_invalid_pans)) as total_missing_pans
from report;


