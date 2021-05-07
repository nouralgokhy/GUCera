CREATE DATABASE GUCera;

Go 

select * from admin
Select * from Users
select * from StudentHasPromocode
USE GUCera;
GO

CREATE TABLE Users(
id int IDENTITY PRIMARY KEY,
firstName varchar(10),
lastName varchar(10),
password varchar(10),
gender binary,
email varchar(10) UNIQUE,
address varchar(10),
);

CREATE TABLE Instructor(
id int PRIMARY KEY REFERENCES Users(id) on DELETE CASCADE on UPDATE CASCADE,
rating DECIMAL(2,1)
);



CREATE TABLE UserMobileNumber(
id int REFERENCES Users(id) on DELETE CASCADE on UPDATE CASCADE,
mobileNumber varchar(11),
PRIMARY KEY(id, mobileNumber)
);


CREATE TABLE Student (
id int PRIMARY KEY REFERENCES Users(id) on DELETE CASCADE on UPDATE CASCADE,
gpa DECIMAL(3,2),

);


CREATE TABLE Admin(
id int PRIMARY KEY REFERENCES Users(id) on DELETE CASCADE on UPDATE CASCADE,
);


CREATE TABLE Course(
id int IDENTITY PRIMARY KEY ,
creditHours int,
name varchar(10) UNIQUE,
courseDescription varchar(200), 
price DECIMAL(6,2),
content varchar(200),
adminId int REFERENCES Admin(id) on DELETE No ACTION on UPDATE No ACTION,
instructorId int REFERENCES Instructor(id) on DELETE CASCADE on UPDATE CASCADE,
accepted BIT
);


CREATE TABLE Assignment(
cid int REFERENCES Course(id) on DELETE CASCADE on UPDATE CASCADE,
number int,
type varchar(10),
fullGrade int,
weight decimal(4,1),
Check (weight between 0 and 100),
deadline datetime,
content varchar(200),
CHECK (type in ('quiz', 'exam', 'project')),
PRIMARY KEY(cid, number,type)
);

CREATE TABLE Feedback(
cid int REFERENCES Course(id) on DELETE NO ACTION on UPDATE NO ACTION,
number int identity,
comment varchar(100),
numberOfLikes int DEFAULT 0,
sid int REFERENCES Student(id) on DELETE SET NULL on UPDATE CASCADE,
PRIMARY KEY(cid, number)
);


CREATE TABLE Promocode(
code varchar(6) PRIMARY KEY,
isuueDate datetime,
expiryDate datetime,
discount decimal(4,2),
adminId int REFERENCES Admin(id) on DELETE SET NULL on UPDATE CASCADE,
);

CREATE TABLE StudentHasPromocode(
sid int REFERENCES Student(id) on DELETE NO ACTION on UPDATE NO ACTION,
code varchar(6) REFERENCES Promocode(code) on DELETE CASCADE on UPDATE CASCADE,
PRIMARY KEY (sid, code)
);

CREATE TABLE CreditCard(
number varchar(15) PRIMARY KEY,
cardHolderName varchar(16),
expiryDate datetime,
cvv varchar(3)
);

CREATE TABLE StudentAddCreditCard(
sid int REFERENCES Student(id) on DELETE CASCADE on UPDATE CASCADE,
creditCardNumber varchar(15) REFERENCES CreditCard on DELETE CASCADE on UPDATE CASCADE
PRIMARY KEY (sid, creditCardNumber)
);

SELECT * FROM UserMobileNumber
CREATE TABLE StudentTakeCourse(
sid int REFERENCES Student(id) on DELETE CASCADE on UPDATE CASCADE,
cid int REFERENCES Course(id) on DELETE NO ACTION on UPDATE NO ACTION,
insid int REFERENCES Instructor(id) on DELETE NO ACTION on UPDATE NO ACTION,
payedfor BIT,
grade decimal(5,2),
Check (grade between 0 and 100),
PRIMARY KEY (sid, cid, insid) 
);


CREATE TABLE StudentTakeAssignment(
sid int REFERENCES Student(id) on DELETE CASCADE on UPDATE CASCADE,
cid int, 
assignmentNumber int,
assignmenttype varchar(10),
grade decimal(5,2),
Check (grade between 0 and 100),
PRIMARY KEY(sid, cid, assignmentNumber,assignmenttype),
Foreign KEY (cid, assignmentNumber,assignmenttype) REFERENCES Assignment(cid, number,type) on DELETE No Action on UPDATE No Action, 
);


CREATE TABLE StudentRateInstructor(
sid int REFERENCES Student(id) on DELETE CASCADE on UPDATE CASCADE,
insid int REFERENCES Instructor(id) on DELETE No Action on UPDATE No Action,
rate DECIMAL(2,1),
PRIMARY KEY(sid, insid)
);

CREATE TABLE StudentCertifyCourse(
sid int REFERENCES Student(id) on DELETE CASCADE on UPDATE CASCADE,
cid int REFERENCES Course(id) on DELETE No Action on UPDATE No Action,
issueDate datetime,
PRIMARY KEY(sid, cid)
);

CREATE TABLE CoursePrerequisiteCourse(
cid int REFERENCES Course(id) on DELETE CASCADE on UPDATE CASCADE,
preid int REFERENCES Course(id) on DELETE No Action on UPDATE No Action,
PRIMARY KEY(cid, preid)
);

CREATE TABLE InstructorTeachCourse(
insid int REFERENCES Instructor(id) on DELETE CASCADE on UPDATE CASCADE,
cid int REFERENCES Course(id) on DELETE No Action on UPDATE No Action,
PRIMARY KEY(insid, cid),
);

go
----------------------------------------
CREATE Proc userLogin
@id int,
@password varchar(20),
@success bit output,
@type int output
as
begin
if exists(
select ID,password
from Users
where id=@id and password=@password)
begin
set @success =1
-- check user type 0-->Instructor,1-->Admin,2-->Student
if exists(select id from Instructor where id=@id)
set @type=0
if exists(select id from Admin where id=@id)
set @type=1
if exists(select id from Student where id=@id)
set @type=2
end
else 
begin
set @success=0
set @type=-1
end
end
go

--------------------------------------------------------------
CREATE Proc studentRegister
@first_name varchar(20),
@last_name varchar(20),
@password varchar(20),
@email varchar(50),
@gender bit,
@address varchar(10)
as
begin
insert into Users(firstName,lastName,password,email,gender,address)
values(@first_name,@last_name,@password,@email,@gender,@address)
declare @id int
SELECT @id=SCOPE_IDENTITY()
insert into Student values(@id,0)	
end
go  

----------------------------------------------------
CREATE Proc InstructorRegister
@first_name varchar(20),
@last_name varchar(20),
@password varchar(20),
@email varchar(10),
@gender bit,
@address varchar(10)
as
begin
insert into Users(firstName,lastName,password,email,gender,address)
values(@first_name,@last_name,@password,@email,@gender,@address)
declare @id int
SELECT @id=SCOPE_IDENTITY()
insert into Instructor values(@id,0)
end
go  
-------------------------------------------------------------

CREATE Proc addMobile
@ID varchar(20),
@mobile_number varchar(20)
as
begin
if @ID is not null and @mobile_number is not null
insert into UserMobileNumber values(@ID,@mobile_number)
end
go

-------------------------------------------------------------
--- 1 List all instructors in the system ----

CREATE Proc AdminListInstr
As
Select u.firstName, u.lastName
from Users u inner join Instructor i on u.id = i.id
go


--- 2 view the profile of any instructor that contains all his/her information -----
CREATE Proc AdminViewInstructorProfile
@instrId int
As
Select u.firstName, u.lastName, u.gender, u.email, u.address, i.rating
from Users u inner join Instructor i on u.id = i.id
WHERE @instrId = i.id
go

--- 3 List all courses in the system ------
CREATE Proc AdminViewAllCourses
As
Select name, creditHours, price, content, accepted
From Course
go

--- 4 List all the courses added by instructors not yet accepted ----
CREATE Proc AdminViewNonAcceptedCourses
As
Select id,name, creditHours, price, content
From Course
Where accepted = 0 or accepted is null


Go

---- 5 View any course details such as course description and content ----
CREATE Proc AdminViewCourseDetails
@courseId int
As
Select name, creditHours, price, content, accepted
From Course
Where @courseId = id

Go
--- 6 Accept/Reject any of the requested courses that are added by instructors ---
CREATE Proc AdminAcceptRejectCourse
@adminid int,
@courseId int
As
UPDATE Course
SET accepted = 1 , adminId=@adminid
Where id = @courseId

Go
--- 7 CREATE new Promo codes by inserting all promo code detail ---
CREATE Proc AdminCREATEPromocode
@code varchar(6),
@isuueDate datetime,
@expiryDate datetime,
@discount decimal(4,2),
@adminId int
As
IF @code is Null or
@isuueDate is Null or 
@expiryDate is Null or
@discount is Null or
@adminId is Null
Print 'Cannot CREATE promocode'
Else
Insert into Promocode Values(@code,@isuueDate,@expiryDate,@discount,@adminId)
go




--- 8 List all students in the system -----
CREATE Proc AdminListAllStudents
As
Select u.firstName, u.lastName
from Users u inner join Student s on u.id = s.id

Go 

--- 9  view the profile of any student that contains all his/her information ----
CREATE Proc AdminViewStudentProfile
@sid int
As
Select u.firstName, u.lastName, u.gender, u.email, u.address, s.gpa
from Users u inner join Student s on u.id = s.id
WHERE @sid = s.id


Go
----- 10 Issue the promo code CREATEd to any student ----
CREATE Proc AdminIssuePromocodeToStudent
@sid int,
@pid varchar(6)
As
If @pid is Null or
@sid is Null
Print 'Error'
Else
Insert into StudentHasPromocode Values(@sid, @pid)
Insert into StudentCertifyCourse Values (4,2,'1/1/2020');


go
-----------------------------------------------------------------
--Instructor
--- 1 Add a new course content and description  ----
CREATE Proc InstAddCourse
@creditHours int,
@name varchar(10),
@price DECIMAL(6,2),
@instructorId int,
@content varchar(200),
@description varchar(200)
As
if(exists(select * from Instructor where id=@instructorId))
Insert into Course(creditHours,name,price,instructorId,courseDescription,content) values
(@creditHours,@name,@price,@instructorId,@description,@content)
declare @cid int
select @cid = SCOPE_IDENTITY()
insert into InstructorTeachCourse(cid,insid) values(@cid,@instructorId)


go
--- 2 update course content  ----
CREATE Proc UpdateCourseContent
@instrId int,
@courseId int, 
@content varchar(200)
As
if(exists(select * from Course where id=@courseId))
update Course 
set content=@content
where id=@courseId and accepted <>0 and accepted is not null and instructorId=@instrId
go 
----------------------------------------------------------
--- 3 update course description ----

CREATE Proc UpdateCourseDescription
@instrId int,
@courseId int,
@courseDescription varchar(200)
As
if(exists(select * from Course where id=@courseId))
update Course 
set courseDescription=@courseDescription
where id=@courseId and accepted <>0 and accepted is not null and instructorId=@instrId
go

--- 4 add another instructor to the course  ----
CREATE Proc AddAnotherInstructorToCourse
@insid int,
@cid int,
@adderIns int
As
if(exists(select * from Course where instructorId=@adderIns and id =@cid ))
Insert into InstructorTeachCourse(insid,cid) values(@insid, @cid)
else 
print 'ERROR'

Go

--- 5 List my courses that were accepted by the admin ----
CREATE Proc InstructorViewAcceptedCoursesByAdmin
@instrId int
As
Select id ,name, creditHours
From Course
Where accepted=1 and instructorId=@instrId
go

----------------------------------------------------------
CREATE Proc DefineCoursePrerequisites
@cid int ,
@prerequsiteId int
As
if(exists(select * from Course where id=@cid))
Insert into CoursePrerequisiteCourse values (@cid,@prerequsiteId)
go

--- 6 Define Assignment of a course of a certian type ----
CREATE Proc DefineAssignmentOfCourseOfCertianType
@instId int,
@cid int ,
@number int,
@type varchar(10),
@fullGrade int,
@weight decimal(4,1),
@deadline datetime,
@content varchar(200)
As
if(exists(select * from Course where id=@cid and instructorId =@instId))
begin
Insert into Assignment values (@cid ,@number,@type,@fullGrade,@weight ,@deadline ,@content)
print 'Assignment Defined'
end
else
print 'You are not allowed to define assignments for this course'
go

--- 7 Instructor view his profile  ----
CREATE Proc ViewInstructorProfile 
@instrId int
As
Select u.firstName, u.lastName, u.gender, u.email, u.address, i.rating, im.mobileNumber
from Users u inner join Instructor i on u.id = i.id
left outer join  UserMobileNumber im on im.id=u.id
WHERE i.id=@instrId 
go

--- 8 Instructor view assignments of his students  ----

CREATE Proc InstructorViewAssignmentsStudents
@instrId int,
@cid int 
As
Select sid ,cid,assignmentNumber, assignmenttype, grade
From StudentTakeAssignment S inner join course c on s.cid = c.id
Where cid=@cid and c.instructorId =@instrId
go


--- 9 Instructor grade the assignemnt submitted by the student  ----
CREATE Proc InstructorgradeAssignmentOfAStudent 
@instrId int,
@sid int ,
@cid int, 
@assignmentNumber int,
@type varchar(10),
@grade decimal(5,2)
As
if(exists(select * from StudentTakeAssignment S inner join Course C 
on C.id =S.cid where cid=@cid and assignmentNumber=@assignmentNumber and sid=@sid and instructorId= @instrId and assignmenttype=@type))
update StudentTakeAssignment
set grade=@grade
where sid=@sid and cid=@cid and assignmentNumber=@assignmentNumber and assignmenttype =@type
go

--- 10 View feedbacks added by students on my course  ----


CREATE Proc ViewFeedbacksAddedByStudentsOnMyCourse 
@instrId int,
@cid int
As
Select number,comment ,numberOfLikes
From Feedback f inner join course c on c.id = f.cid
Where cid=@cid and instructorId =@instrId 
go

CREATE Proc updateInstructorRate   
@insid int 
As
if(exists(select * from Instructor where id=@insid))
declare @avgRating float
select @avgRating=avg(rate)
from StudentRateInstructor
where insid=@insid

update Instructor 
set rating=@avgRating
where id=@insid

GO
CREATE Proc calculateFinalGrade
@cid int ,
@sid int ,
@insId int
AS
BEGIN
declare @fullGrade int 
select @fullGrade=Sum ((weight/100)*fullgrade ) 
From Assignment
where cid=@cid

declare @studentScore int 
select @studentScore=sum(grade)
from StudentTakeAssignment
where sid=@sid and cid=@cid

update StudentTakeCourse
set grade =@studentScore
where cid=@cid and sid=@sid and insid=@insId

END

GO

--- 12 instructor issue certificate to a student   ----
CREATE Proc InstructorIssueCertificateToStudent
@cid int ,
@sid int ,
@insId int,
@issueDate datetime 
As
if(
exists(select * from StudentTakeCourse where sid=@sid and grade >2.0 and cid=@cid))
Begin 
print 'Certificate issued successfully'
Insert into StudentCertifyCourse values (@sid,@cid,@issueDate)
end
else 
print 'Invalid ID'


GO
-----------------------------------------------------------------------
--Student

CREATE FUNCTION checkStudentEnrolledInCourse
(@sid INT, @cid INT)
RETURNS BIT
BEGIN
DECLARE @returnValue BIT
IF(EXISTS(SELECT * FROM StudentTakeCourse WHERE sid = @sid AND cid = @cid))
SET @returnValue = '1'
ELSE
SET @returnValue = '0'
RETURN @returnValue
END
go
CREATE Proc viewMyProfile
@id int 
AS
BEGIN
IF (EXISTS(Select * FROM Users WHERE id = @id  ))
SELECT * FROM Student INNER JOIN Users ON Student.id = Users.id
WHERE Student.id = @id
ELSE
print 'User not found'
END
go

CREATE Proc editMyProfile
@id int,
@firstName varchar(10),
@lastName varchar(10),
@password varchar(10),
@gender binary,
@email varchar(10),
@address varchar(10)
AS
IF (EXISTS(SELECT * FROM Users WHERE id=@id))
BEGIN
IF (@firstName IS NOT NULL )
UPDATE Users SET firstName = @firstName WHERE id=@id
IF (@lastName IS NOT NULL)
UPDATE Users SET lastName = @lastName WHERE id=@id
IF (@password IS NOT NULL)
UPDATE Users SET [password] = @password WHERE id=@id
IF (@gender IS NOT NULL)
UPDATE Users SET gender = @gender WHERE id=@id
IF (@email IS NOT NULL)
UPDATE Users SET email = @emaiL WHERE id=@id
IF (@address IS NOT NULL)
UPDATE Users SET address = @address WHERE id=@id
END
ELSE
print 'User not found'

SELECT * FROM StudentTakeCourse
go
CREATE Proc availableCourses

	AS
	SELECT id,name
	FROM Course 
	WHERE accepted = 1

go

CREATE Proc courseInformation
@id int
AS
IF(EXISTS(SELECT * FROM Course WHERE id = @id))
BEGIN
SELECT Course.*, Users.firstName,Users.lastName FROM Course  INNER JOIN Instructor ON Course.instructorId = Instructor.id 
INNER JOIN Users ON Instructor.id = Users.id
WHERE Course.id = @id
END

go

--Enroll in a course which I had viewed its information.
-- which instructor ??
CREATE Proc enrollInCourse
@sid INT,
@cid INT,
@instr int
AS
BEGIN
If (EXISTS ((select * from InstructorTeachCourse where insid = @instr and cid=@cid )))
Begin
if (exists(select * from CoursePrerequisiteCourse where cid=@cid))
begin
if(exists(select * from StudentTakeCourse where sid=@sid and 
cid in (select preid from CoursePrerequisiteCourse where cid=@cid) ) )
INSERT INTO StudentTakeCourse (sid,cid,insid) VALUES (@sid,@cid,@instr)
else
print 'Student didnt take this course pre-requisite'
end
else 
INSERT INTO StudentTakeCourse (sid,cid,insid) VALUES (@sid,@cid,@instr)
END
else
print 'This instructor does not teach this course'
END
go
CREATE Proc addCreditCard
@sid int,
@number varchar(15),
@cardHolderName varchar(16),
@expiryDate datetime,
@cvv varchar(3)
AS
IF (EXISTS(SELECT * FROM Users WHERE id=@sid))
BEGIN
INSERT INTO CreditCard VALUES (@number,@cardholderName,@expiryDate,@cvv)
insert into StudentAddCreditCard values(@sid,@number)
END
go 

CREATE Proc viewPromocode
@sid int
AS
SELECT P.* FROM Promocode  P inner join StudentHasPromocode SP on SP.code = P.code 
where SP.sid=@sid
go


CREATE Proc enrollInCourseViewContent
@id int,
@cid int
AS
BEGIN
IF (EXISTS(SELECT * FROM Users WHERE id=@id))
SELECT C.* FROM Course C INNER JOIN StudentTakeCourse STC ON C.id = STC.cid INNER JOIN Student S ON STC.sid = S.id 
INNER JOIN Users Us ON Us.id = S.id
WHERE Us.id = @id and c.id=@cid
ELSE
print 'not a user'
END

go

CREATE Proc viewAssign
@courseId int,
@Sid int
AS
BEGIN
IF (EXISTS(SELECT * FROM Users WHERE id=@Sid))
SELECT A.* FROM Assignment A INNER JOIN Course C 
ON A.cid = C.id WHERE C.id = @courseId
ELSE
print 'not a user'
END
go

CREATE Proc submitAssign
@assignType VARCHAR(10),
@assignnumber int,
@sid INT,
@cid INT
AS
BEGIN
IF (EXISTS(SELECT * FROM StudentTakeCourse WHERE cid = @cid AND sid = @sid ))
Begin
INSERT INTO StudentTakeAssignment values (@sid,@cid,@assignnumber,@assignType,null)
print 'Assignment submitted successfully'
end
ELSE
print 'not enrolled in course'
END
GO
--View the grades of each assignment type.

CREATE Proc viewAssignGrades ---5(l)

 @assignnumber int, 
 @assignType VARCHAR(10), 
 @cid INT, 
 @sid INT,
 @assignGrade INT OUTPUT

AS
	IF(EXISTS(SELECT * FROM Assignment WHERE type = @assignType AND number = @assignnumber AND cid = @cid) AND EXISTS(SELECT * FROM StudentTakeAssignment WHERE assignmentType = @assignType AND assignmentNumber = @assignnumber AND cid = @cid AND sid = @sid))
		BEGIN 
			SELECT @assignGrade = grade
			FROM StudentTakeAssignment
			WHERE assignmentNumber = @assignnumber AND assignmentType = @assignType AND cid = @cid AND sid = @sid
		END
	ELSE
		PRINT 'You did not submit'

GO

--I can add feedback for the course I am enrolled in.
CREATE Proc addFeedback
@comment VARCHAR(100),
@cid INT,
@sid INT
AS
BEGIN 
IF(dbo.checkStudentEnrolledInCourse(@sid,@cid)='1')
Begin
INSERT INTO Feedback (cid,comment,sid) VALUES (@cid,@comment,@sid)
print 'Feedback added successfully'
end
ELSE
print 'student not enrolled in course'
END

GO
CREATE Proc rateInstructor
@rate DECIMAL (2,1),
@sid INT,
@insid INT
AS
BEGIN
IF(dbo.checkStudentEnrolledInCourse(@sid,@insid)='1')
INSERT INTO StudentRateInstructor (sid,insid,rate) VALUES (@sid,@insid,@rate)
ELSE
print 'student not enrolled in insturctor course'
END
EXEC availableCourses

GO

CREATE PROC viewCertificate
@cid INT,
@sid INT
AS
BEGIN
IF (dbo.checkStudentEnrolledInCourse(@sid,@cid)='1' AND EXISTS(SELECT STC.grade FROM StudentTakeCourse STC
INNER JOIN Course C ON STC.cid = C.id WHERE C.id= @cid and STC.grade is not null) AND EXISTS(SELECT * FROM StudentCertifyCourse WHERE sid = @sid AND cid = @cid ))
SELECT DISTINCT c.name,STC.grade,SCC.issueDate FROM StudentCertifyCourse SCC INNER JOIN Course c on SCC.cid = c.id  INNER JOIN StudentTakeCourse STC on SCC.sid = STC.sid and SCC.cid= STC.cid WHERE SCC.sid = @sid AND SCC.cid = @cid
ELSE
print 'student not enrolled in course or did not finish course'
END

GO

CREATE Proc viewFinalGrade
@cid INT,
@sid INT,
@finalgrade decimal(10,2) OUTPUT
AS 
BEGIN
IF(dbo.checkStudentEnrolledInCourse(@sid,@cid) = '1' )
SELECT @finalgrade=Grade 
FROM StudentTakeCourse 
where cid=@cid and sid=@sid
END



GO

CREATE Proc payCourse
@cid INT,
@sid INT
AS
BEGIN
IF (EXISTS(SELECT * FROM StudentHasPromoCode WHERE sid = @sid ))
update studenStudentTakeCourse
set payedfor =1
where  cid = @cid and  sid=@sid

END
