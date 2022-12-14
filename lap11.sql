
create table Lop(
MaLop char(5) not null primary key, 
TenLop nvarchar(20), 
SiSo int)
create table Sinhvien(
MaSV char(5) not null primary key,
Hoten nvarchar(20), 
Ngaysinh date, 
MaLop char(5) constraint fk_malop references lop(malop))
create table MonHoc(
MaMH char(5) not null primary key, 
TenMH nvarchar(20))
create table KetQua(
MaSV char(5) not null, 
MaMH char(5) not null, 
Diemthi float,
constraint fk_Masv foreign key(MaSV) references sinhvien(MaSV),
constraint fk_Mamh foreign key(MaMH) references Monhoc(MaMH),
constraint pk_Masv_Mamh primary key(Masv, mamh))
insert lop values
('a','lop a',0),
('b','lop b',0),
('c','lop c',0)
insert sinhvien values
('01','ABC','2000-1-1','a'),
('02','BCD','2000-2-2','a'),
('03','CDF','2000-3-3','a')
insert monhoc values
('P','PPP'),
('C','CCC'),
('Q','HHH'),
('W','WWW')
insert KetQua values
('01','P',8),
('01','Q',7),
('02','P',8),
('01','CL',5),
('02','W',5)
--1.Viết hàm diemtb dạng Scarlar function tính điểm trung bình của một sinh viên bất kỳ
go
create function diemtb (@msv char(5))
returns float
as
begin
 declare @tb float
 set @tb = (select avg(Diemthi)
 from KetQua
where MaSV=@msv) 
 return @tb
end
go
select dbo.diemtb ('01')
--2.Viết hàm bằng 2 cách (table – value fuction và multistatement value function) tính điểm trung bình của cả lớp, thông tin gồm MaSV, Hoten, ĐiemTB, sử dụng hàm diemtb ở câu 1

--cách 1
create function trbinhcalop(@malop char(5))
returns table
as
return
 select s.masv, Hoten, trungbinh=dbo.diemtb(s.MaSV)
 from Sinhvien s join KetQua k on s.MaSV=k.MaSV
 where MaLop=@malop
 group by s.masv, Hoten
--cách 2
go
create function trbinhlop1(@malop char(5))
returns @dsdiemtb table (masv char(5), tensv nvarchar(20), dtb float)
as
begin
 insert @dsdiemtb
 select s.masv, Hoten, trungbinh=dbo.diemtb(s.MaSV)
 from Sinhvien s join KetQua k on s.MaSV=k.MaSV
 where MaLop=@malop
 group by s.masv, Hoten
 return
end
go
select*from trbinhlop1('a')
--3.Viết một thủ tục kiểm tra một sinh viên đã thi bao nhiêu môn, tham số là MaSV, VD sinh viên có MaSV=01thi 3 môn kết quả trả về chuỗi thông báo “Sinh viên 01 thi 3 môn” hoặc “Sinh viên 01 không thi môn nào

create proc ktra @msv char(5)
as
begin 
 declare @n int
 set @n=(select count(*) from ketqua where Masv=@msv)
 if @n=0 
 print 'sinh vien '+@msv + 'khong thi mon nao'
 else
 print 'sinh vien '+ @msv+ 'thi '+cast(@n as char(2))+ 'mon'
end 
go
exec ktra '01'
--4.Viết một trigger kiểm tra sỉ số lớp khi thêm một sinh viên mới vào danh sách sinh viên thì hệ thống cập nhật lại siso của lớp, mỗi lớp tối đa 10SV, nếu thêm vào >10 thì thông báo lớp đầy và hủy giao dịch---
go
create trigger updatesslop
on sinhvien
for insert
as
begin
 declare @ss int
 set @ss=(select count(*) from sinhvien s 
 where malop in(select malop from inserted))
 if @ss>10
 begin
 print 'Lop day'
 rollback tran
 end
 else
 begin
 update lop
 set SiSo=@ss
 where malop in (select malop from inserted)
 end