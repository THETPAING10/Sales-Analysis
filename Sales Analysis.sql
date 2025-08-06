
---product

create view dim_product as
select 
ProductID,
p.Name as 'Product Name',
pm.Name as 'Product Model Name',
isnull(Color,'NA') as 'Color',
SafetyStockLevel,ReorderPoint,
StandardCost,ListPrice,
SizeUnitMeasureCode,
WeightUnitMeasureCode,
ProductLine,
p.ProductSubcategoryID,
ps.Name as 'Product SubCategoryID',
pc.Name as 'Prodcut CategoryID'
from Production.Product p
left join Production.ProductModel pm on p.ProductModelID = pm.ProductModelID
left join Production.ProductSubcategory ps on p.ProductSubcategoryID = ps.ProductSubcategoryID
left join Production.ProductCategory pc on ps.ProductCategoryID = pc.ProductCategoryID


---costing ---> date twe ka		null pr lr yin getdate() nae a sar htoe yan....


----product cost history

create view fct_productcosthistory as

with cost as (
select 
ProductID,StartDate,
EndDate,StandardCost,
DENSE_RANK() over (partition by ProductID order by StartDate desc) as 'Rank' 
from Production.ProductCostHistory
)
select 
ProductID,StartDate,StandardCost,
case [RANK] when 1 then GETDATE() else [EndDate] end as 'EndDate'
from cost

----product price history

create view fct_productpricehistory as
select 
ProductID, StartDate, ISNULL(EndDate,GETDATE()) EndDate,
ListPrice
from Production.ProductListPriceHistory


----Customer 

create view dim_customer as

with FirstStep as (
select 
c.CustomerID,
p.BusinessEntityID,
CONCAT (p.FirstName,' ',p.MiddleName,' ',p.LastName) as FullName,
case when p.Title in('Sr.','Mr.') then 'Male'
when p.Title IS NULL then 'Not Defined' else 'Female' end as Gender,
c.PersonID,
c.StoreID,
a.AddressLine1,a.City,a.PostalCode,
sp.Name as 'State Province Name',
st.Name as 'Territory Name',st.[Group] as 'Territory Group',
cr.Name as 'Country Name',
ROW_NUMBER() over(Partition by p.BusinessEntityID order by c.CustomerID asc) as Rank
from Sales.Customer c 
left join Person.Person p on c.PersonID = p.BusinessEntityID
left join Person.BusinessEntityAddress bea on p.BusinessEntityID = bea.BusinessEntityID
left join Person.Address a on bea.AddressID = a.AddressID
left join Person.StateProvince sp on a.StateProvinceID = sp.StateProvinceID
left join Sales.SalesTerritory st on c.TerritoryID = st.TerritoryID
left join Person.CountryRegion cr on st.CountryRegionCode = cr.CountryRegionCode
where p.BusinessEntityID is not null ) 
select * from FirstStep where [Rank]= 1

---- Supplier List
create view dim_supplier as 
select 
v.BusinessEntityID,
v.Name as 'Supplier Name',
a.AddressLine1,a.City,
sp.Name as 'State Provience Name',
st.Name as 'Territory Name',
st.[Group] as 'Territory Group',
cr.Name as 'Country Name'
from Purchasing.Vendor v
left join Person.BusinessEntityAddress bea on v.BusinessEntityID = bea.BusinessEntityID
left join Person.Address a on bea.AddressID = a.AddressID
left join Person.StateProvince sp on a.StateProvinceID = sp.StateProvinceID
left join Sales.SalesTerritory st on sp.TerritoryID = st.TerritoryID
left join Person.CountryRegion cr on st.CountryRegionCode = cr.CountryRegionCode


---address table

create view dim_Address as 
select 
bea.AddressID,
at.Name as AddressType,
bea.BusinessEntityID,
a.AddressLine1,a.City,
sp.Name as 'State Provience Name',
st.Name as 'Territory Name',
st.[Group] as 'Continent',
a.PostalCode
from Person.BusinessEntityAddress bea
left join Person.Address a on bea.AddressID = a.AddressID
left join Person.StateProvince sp on a.StateProvinceID = sp.StateProvinceID
left join Person.CountryRegion cr on sp.CountryRegionCode = cr.CountryRegionCode
left join Person.AddressType at on bea.AddressTypeID = at.AddressTypeID
left join Sales.SalesTerritory st on sp.TerritoryID = st.TerritoryID


----Sales Table


create view fct_salesdetails as 
select
    SD.SalesOrderID,
    CONCAT(SD.SalesOrderID,'-',SD.SalesOrderDetailID) SalesOrderDetailID,
    SD.ProductID,
    CAST(SH.OrderDate AS date) OrderDate,
    CAST(SH.ShipDate AS date) ShipDate,
    SH.OnlineOrderFlag, SH.CustomerID,
    SH.SalesPersonID, SH.BillToAddressID, SH.ShipToAddressID,
    SD.OrderQty,
    SD.UnitPrice,
    SD.UnitPrice * SD.UnitPriceDiscount AS DiscountAmount,
    SD.UnitPrice - (SD.UnitPrice * SD.UnitPriceDiscount) AS UnitPrice_AfterDiscount,
    SD.LineTotal,
	(sd.LineTotal/sh.SubTotal) * sh.TaxAmt as 'Line Tax Amount',
	(sd.LineTotal/sh.SubTotal) * sh.Freight as 'Line Freight Amount',
	pc.StandardCost
from Sales.SalesOrderDetail SD
Left Join Sales.SalesOrderHeader SH on SD.SalesOrderID = SH.SalesOrderID
left join fct_productcosthistory pc on sd.ProductID = pc.ProductID and sh.OrderDate >= PC.StartDate and sh.OrderDate <=EndDate


---Employee Table
create view dim_salesperson as
select 
emp.BusinessEntityID,CONCAT(p.FirstName,' ',p.MiddleName,' ',p.LastName) as 'Employee Name',
emp.JobTitle,emp.BirthDate,emp.MaritalStatus,emp.Gender,emp.HireDate,
p.PersonType, 

ea.EmailAddress
from HumanResources.Employee emp 
left join Person.Person p on emp.BusinessEntityID = p.BusinessEntityID
left join Person.EmailAddress ea on p.BusinessEntityID = ea.BusinessEntityID
where p.PersonType = 'SP'
