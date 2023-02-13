--drop table if exist

If exists (select 1
	from project.INFORMATION_SCHEMA.TABLES
		where table_name = 'nashnew'
		and TABLE_SCHEMA = 'dbo')

Begin
	drop table project..nashnew
end
go

--create copy of new table

Select * 
into project..nashnew
from project..nash
go

-- convert saledate from datetime to date

alter table project..nashnew
alter column saledate date;

-- update null value of propertyaddress

update a
set PropertyAddress = isnull(a.propertyAddress,b.propertyAddress)
from project..nashnew a
join project..nashnew b
on a.parcelid = b.parcelid
and a.uniqueid <> b.uniqueid
where a.propertyAddress is null;

--split address into street and city

Alter table project..nashnew
add StreetAddress nvarchar(255)

Alter table project..nashnew
add CityAddress nvarchar(255)

go

Update project..nashnew
Set StreetAddress = Substring(propertyaddress,1,charindex(',',propertyaddress)-1)
from project..nashnew

Update project..nashnew
Set CityAddress = substring(propertyaddress,charindex(',',propertyaddress)+1,len(propertyaddress))
from project..nashnew

Alter table project..nashnew
drop column propertyaddress

-- Spliting owner address to street, city, state

alter table project..nashnew
add stateowneraddress nvarchar(250)

alter table project..nashnew
add cityowneraddress nvarchar(250)

alter table project..nashnew
add streetowneraddress nvarchar(250)

go

update project..nashnew
set stateowneraddress = parsename(replace(owneraddress,',','.'),1)

update project..nashnew
set cityowneraddress =parsename(replace(owneraddress,',','.'),2)

update project..nashnew
set streetowneraddress =parsename(replace(owneraddress,',','.'),3)

Alter table project..nashnew
drop column owneraddress

--changing 'Y' and 'N' in sold as vacant to 'Yes' and 'No'

Update project..nashnew
Set SoldAsVacant = 
Case
When SoldAsVacant = 'Y' Then 'Yes'
When SoldAsVacant = 'N' Then 'No'
Else SoldAsVacant
end;

--Deleting Duplicate Data

WITH Dup AS(
Select *,
ROW_NUMBER() OVER (
PARTITION BY ParcelID,
	streetAddress,
	SalePrice,
	SaleDate,
	LegalReference
	order by Uniqueid) as row_num

From Project..Nashnew)

Delete
From Dup
Where row_num > 1

go

--Check Result

Select * from project..nash
Select * from project..nashnew