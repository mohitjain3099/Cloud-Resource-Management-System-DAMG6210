-- 1. Client_Bill_View - Provides detailed billing information along with client details, using an indirect relationship between CLIENT and BILL.
CREATE OR REPLACE VIEW Client_Bill_View AS
SELECT 
    b.BILLID,
    ra.CLIENTID,
    c.FIRSTNAME,
    c.LASTNAME,
    c.EMAIL,
    c.PHONENUMBER,
    c.COMPANYNAME,
    c.STREET,
    c.CITY,
    c.STATE,
    c.ZIPCODE,
    b.BILLPERIODSTART,
    b.BILLPERIODEND,
    b.TOTALAMOUNT,
    b.STATUS
FROM 
    BILL b
JOIN 
    USAGELOG ul ON b.BILLID = ul.BILLID
JOIN 
    RESOURCEALLOCATION ra ON ul.ALLOCATIONID = ra.ALLOCATIONID
JOIN 
    CLIENT c ON ra.CLIENTID = c.CLIENTID;

-- 2. Region_Client_Count - Shows the number of clients in each region.

CREATE OR REPLACE VIEW Region_Client_Count AS
SELECT r.REGION_ID, r.REGION_NAME, COUNT(c.CLIENTID) AS CLIENT_COUNT
FROM REGION r
JOIN STATE_REGION_MAPPING srm ON r.REGION_ID = srm.REGION_ID
JOIN CLIENT c ON srm.STATE_CODE = c.STATE
GROUP BY r.REGION_ID, r.REGION_NAME;

-- 3. Resource_Client_Count - Displays the number of unique clients using each resource type.

CREATE OR REPLACE VIEW Resource_Client_Count AS
SELECT rt.RESOURCETYPEID, rt.TYPENAME, COUNT(DISTINCT ra.CLIENTID) AS CLIENT_COUNT
FROM RESOURCETYPE rt
JOIN RESOURCETABLE r ON rt.RESOURCETYPEID = r.RESOURCETYPEID
JOIN RESOURCEALLOCATION ra ON r.RESOURCEID = ra.RESOURCEID
GROUP BY rt.RESOURCETYPEID, rt.TYPENAME;

-- 4. Billing_Summary_By_Region - Summarizes the total billing amount for each region.

CREATE OR REPLACE VIEW Billing_Summary_By_Region AS
SELECT 
    r.REGION_ID, 
    r.REGION_NAME, 
    SUM(b.TOTALAMOUNT) AS TOTAL_BILLING_AMOUNT
FROM 
    REGION r
JOIN 
    STATE_REGION_MAPPING srm ON r.REGION_ID = srm.REGION_ID
JOIN 
    CLIENT c ON srm.STATE_CODE = c.STATE
JOIN 
    RESOURCEALLOCATION ra ON c.CLIENTID = ra.CLIENTID
JOIN 
    USAGELOG ul ON ra.ALLOCATIONID = ul.ALLOCATIONID
JOIN 
    BILL b ON ul.BILLID = b.BILLID
GROUP BY 
    r.REGION_ID, r.REGION_NAME;
 
-- 5. Resource_Usage_Summary - Summarizes total usage amount and cost for each resource type.

CREATE OR REPLACE VIEW Resource_Usage_Summary AS
SELECT 
    rt.RESOURCETYPEID, 
    rt.TYPENAME, 
    SUM(ul.USAGEAMOUNT) AS TOTAL_USAGE_AMOUNT, 
    SUM(ul.TOTALCOST) AS TOTAL_USAGE_COST
FROM 
    RESOURCETYPE rt
JOIN 
    RESOURCETABLE r ON rt.RESOURCETYPEID = r.RESOURCETYPEID
JOIN 
    RESOURCEALLOCATION ra ON r.RESOURCEID = ra.RESOURCEID
JOIN 
    USAGELOG ul ON ra.ALLOCATIONID = ul.ALLOCATIONID
GROUP BY 
    rt.RESOURCETYPEID, rt.TYPENAME;

-- 6. Overdue_Bills - Lists overdue bills (unpaid bills past their billing period end date) with client information.

CREATE OR REPLACE VIEW Overdue_Bills AS
SELECT 
    b.BILLID, 
    ra.CLIENTID, 
    c.FIRSTNAME || ' ' || c.LASTNAME AS CLIENT_NAME, 
    b.BILLPERIODEND, 
    b.TOTALAMOUNT, 
    b.STATUS
FROM 
    BILL b
JOIN 
    USAGELOG ul ON b.BILLID = ul.BILLID
JOIN 
    RESOURCEALLOCATION ra ON ul.ALLOCATIONID = ra.ALLOCATIONID
JOIN 
    CLIENT c ON ra.CLIENTID = c.CLIENTID
WHERE 
    b.STATUS = 'Unpaid' 
    AND b.BILLPERIODEND < SYSDATE;

-- 7. Active_Resource_Allocations - Shows currently active resource allocations for each client.

CREATE OR REPLACE VIEW Active_Resource_Allocations AS
SELECT ra.ALLOCATIONID, ra.CLIENTID, c.FIRSTNAME || ' ' || c.LASTNAME AS CLIENT_NAME, ra.RESOURCEID, r.STATUS AS RESOURCE_STATUS, 
       ra.ALLOCATIONDATE, ra.EXPIRATIONDATE
FROM RESOURCEALLOCATION ra
JOIN CLIENT c ON ra.CLIENTID = c.CLIENTID
JOIN RESOURCETABLE r ON ra.RESOURCEID = r.RESOURCEID
WHERE ra.STATUS = 'Approved' AND ra.EXPIRATIONDATE >= SYSDATE;

-- 8. Client_Resource_Allocation_History - Provides a historical view of resource allocations for each client.

CREATE OR REPLACE VIEW Client_Resource_Allocation_History AS
SELECT 
    ra.CLIENTID, 
    c.FIRSTNAME || ' ' || c.LASTNAME AS CLIENT_NAME, 
    ra.ALLOCATIONID,  -- Ensure this column is included
    ra.RESOURCEID, 
    ra.ALLOCATIONDATE, 
    ra.EXPIRATIONDATE, 
    ra.STATUS
FROM 
    RESOURCEALLOCATION ra
JOIN 
    CLIENT c ON ra.CLIENTID = c.CLIENTID
ORDER BY 
    ra.CLIENTID, 
    ra.ALLOCATIONDATE;

-- 9. Client_Pricing_Plan_View - Displays each client with their chosen pricing plan.

CREATE OR REPLACE VIEW Client_Pricing_Plan_View AS
SELECT 
    c.CLIENTID,
    c.FIRSTNAME,
    c.LASTNAME,
    c.EMAIL,
    c.PHONENUMBER,
    c.COMPANYNAME,
    c.CITY,
    c.STATE,
    pp.PLANID,
    pp.PLANNAME,
    pp.DESCRIPTION
FROM 
    CLIENT c
JOIN 
    RESOURCEALLOCATION ra ON c.CLIENTID = ra.CLIENTID
JOIN 
    PRICINGDETAIL pd ON ra.RESOURCEID = pd.RESOURCETYPEID
JOIN 
    PRICINGPLAN pp ON pd.PLANID = pp.PLANID
GROUP BY 
    c.CLIENTID, c.FIRSTNAME, c.LASTNAME, c.EMAIL, c.PHONENUMBER, 
    c.COMPANYNAME, c.CITY, c.STATE, pp.PLANID, pp.PLANNAME, pp.DESCRIPTION;