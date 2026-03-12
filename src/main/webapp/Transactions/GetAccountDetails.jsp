<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%
    String accountCode = request.getParameter("accountCode");
    
    if (accountCode == null || accountCode.trim().isEmpty()) {
        out.print("{\"error\": \"Account code is required\"}");
        return;
    }
    
    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        con = DBConnection.getConnection();
        
        // Query to get balances, product name, GL account code and GL account name using functions
        String query = "SELECT " +
       "LEDGERBALANCE, " +
       "AVAILABLEBALANCE, " +
       "FN_GET_AC_GL(?) AS GL_ACCOUNT_CODE, " +
       "Fn_Get_Account_name(FN_GET_AC_GL(?)) AS GL_ACCOUNT_NAME, " +
       "FN_GET_CUSTOMER_ID(?) AS CUSTOMER_ID, " +
       "Fn_Get_Customer_Aadhar(FN_GET_CUSTOMER_ID(?)) AS AADHAR_NUMBER, " +
       "Fn_Get_Cust_PAN(FN_GET_CUSTOMER_ID(?)) AS PAN_NUMBER, " +
       "Fn_Get_Cust_ZIPNO(FN_GET_CUSTOMER_ID(?)) AS ZIPCODE " +  
       "FROM BALANCE.ACCOUNT " +
       "WHERE ACCOUNT_CODE = ?";
        
        ps = con.prepareStatement(query);
        ps.setString(1, accountCode);  // For FN_GET_AC_GL function
        ps.setString(2, accountCode);  // For Fn_Get_Account_name(FN_GET_AC_GL(?))
        ps.setString(3, accountCode);  // For FN_GET_CUSTOMER_ID function
        ps.setString(4, accountCode);  // For Fn_Get_Cust_aadhar(FN_GET_CUSTOMER_ID(?))
        ps.setString(5, accountCode);  // For Fn_Get_Cust_PAN(FN_GET_CUSTOMER_ID(?))
        ps.setString(6, accountCode);  // For Fn_Get_Cust_ZIPNO(FN_GET_CUSTOMER_ID(?)) 
        ps.setString(7, accountCode);  // For the WHERE clause - CHANGE FROM 6 to 7
        rs = ps.executeQuery();
        
        if (rs.next()) {
            String glAccountCode = rs.getString("GL_ACCOUNT_CODE");
            String glAccountName = rs.getString("GL_ACCOUNT_NAME");
            String aadharNumber = rs.getString("AADHAR_NUMBER");
            String panNumber = rs.getString("PAN_NUMBER");
            String zipcode = rs.getString("ZIPCODE");  
            
            // Clean up the GL account code (trim and check for default value)
            if (glAccountCode != null) {
                glAccountCode = glAccountCode.trim();
                // Check if it's the default "not found" value
                if ("00000000000000".equals(glAccountCode)) {
                    glAccountCode = "";
                    glAccountName = "";
                }
            } else {
                glAccountCode = "";
            }
            
         	// Clean up Aadhar number
            if (aadharNumber != null) {
                aadharNumber = aadharNumber.trim();
                // Check if it's the default error value from function
                if (".".equals(aadharNumber)) {
                    aadharNumber = "";
                }
            } else {
                aadharNumber = "";
            }
         // Clean up PAN number
            if (panNumber != null) {
                panNumber = panNumber.trim();
                // Check if it's the default error value from function
                if ("0".equals(panNumber)) {
                    panNumber = "";
                }
            } else {
                panNumber = "";
            }
            
            // Clean up ZIP code 
            if (zipcode != null) {
                zipcode = zipcode.trim();
                // Check if it's the default error value from function
                if (".".equals(zipcode)) {
                    zipcode = "";
                }
            } else {
                zipcode = "";
            }
            
         // Build JSON response
            out.print("{");
            out.print("\"success\": true,");
            out.print("\"ledgerBalance\": \"" + (rs.getBigDecimal("LEDGERBALANCE") != null ? rs.getBigDecimal("LEDGERBALANCE") : "0.00") + "\",");
            out.print("\"availableBalance\": \"" + (rs.getBigDecimal("AVAILABLEBALANCE") != null ? rs.getBigDecimal("AVAILABLEBALANCE") : "0.00") + "\",");
            out.print("\"glAccountCode\": \"" + glAccountCode + "\",");
            out.print("\"glAccountName\": \"" + glAccountName + "\",");
            out.print("\"customerId\": \"" + (rs.getString("CUSTOMER_ID") != null ? rs.getString("CUSTOMER_ID").trim() : "") + "\",");
            out.print("\"aadharNumber\": \"" + aadharNumber + "\",");
            out.print("\"panNumber\": \"" + panNumber + "\",");
            out.print("\"zipcode\": \"" + zipcode + "\"");  
            out.print("}");
        } else {
            out.print("{\"error\": \"Account not found in balance table\"}");
        }
        
    } catch (SQLException e) {
        e.printStackTrace();
        out.print("{\"error\": \"Database error: " + e.getMessage() + "\"}");
    } finally {
        if (rs != null) try { rs.close(); } catch(SQLException e) {}
        if (ps != null) try { ps.close(); } catch(SQLException e) {}
        if (con != null) try { con.close(); } catch(SQLException e) {}
    }
%>