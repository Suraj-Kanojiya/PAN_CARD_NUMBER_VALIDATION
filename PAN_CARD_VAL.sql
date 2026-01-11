
--Invalid object name occurs when SQL Server cannot find the object in the current database or schema. Using the fully qualified name or switching the database resolves it
USE PANCARD; 
GO

--PAN Number Validation Project--
Select * from PANNumberData;

Alter table PANNumberData Alter Column Pan_numbers varchar(50);

--check for duplicates--
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

--Cleaned pan numbers plus All letters in uppercase
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

Create Function dbo.adj_char(@pstr Varchar(50))
Returns BIT
AS 
Begin
   Declare @i int=1;
   Declare @len INT = LEN(@pstr);

   While @i<@len 
   Begin
      if  SUBSTRING (@pstr, @i,1)=SUBSTRING(@pstr, @i+1,1)
	    return 1; -- Adj characters same
	  SET @i=@i+1;
   END
   Return 0; -- Adj Characters not same

END;

Select dbo.adj_char('JJCHK4574O')


Create Function dbo.adj_charseq(@pstr Varchar(50))
Returns BIT
AS 
Begin
   Declare @i int=1;
   Declare @len INT = LEN(@pstr);

   While @i<@len 
   Begin
      if ASCII(SUBSTRING (@pstr, @i+1,1))-ASCII(SUBSTRING(@pstr, @i,1))=1
	    return 1; -- characters in SEQ
	  SET @i=@i+1;
   END
   Return 0; -- Characters not in seq

END;
Select dbo.adj_charseq('ACZSE2852I')