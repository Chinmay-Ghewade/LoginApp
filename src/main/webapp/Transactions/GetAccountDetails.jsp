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
        
        // Query to get balances and customer address using Fn_Get_Cust_address function
        String query = "SELECT " +
       "LEDGERBALANCE, " +
       "AVAILABLEBALANCE, " +
       "FN_GET_CUSTOMER_ID(?) AS CUSTOMER_ID, " +
       "Fn_Get_Cust_address(FN_GET_CUSTOMER_ID(?)) AS CUSTOMER_ADDRESS, " +
       "Fn_Get_Customer_Aadhar(FN_GET_CUSTOMER_ID(?)) AS AADHAR_NUMBER, " +
       "Fn_Get_Cust_PAN(FN_GET_CUSTOMER_ID(?)) AS PAN_NUMBER, " +
       "Fn_Get_Cust_ZIPNO(FN_GET_CUSTOMER_ID(?)) AS ZIPCODE " +  
       "FROM BALANCE.ACCOUNT " +
       "WHERE ACCOUNT_CODE = ?";
        
        ps = con.prepareStatement(query);
        ps.setString(1, accountCode);  // For FN_GET_CUSTOMER_ID function
        ps.setString(2, accountCode);  // For Fn_Get_Cust_address(FN_GET_CUSTOMER_ID(?))
        ps.setString(3, accountCode);  // For Fn_Get_Customer_Aadhar(FN_GET_CUSTOMER_ID(?))
        ps.setString(4, accountCode);  // For Fn_Get_Cust_PAN(FN_GET_CUSTOMER_ID(?))
        ps.setString(5, accountCode);  // For Fn_Get_Cust_ZIPNO(FN_GET_CUSTOMER_ID(?))
        ps.setString(6, accountCode);  // For the WHERE clause - ACCOUNT_CODE
        
        rs = ps.executeQuery();
        
        if (rs.next()) {
            String customerId = rs.getString("CUSTOMER_ID");
            String customerAddress = rs.getString("CUSTOMER_ADDRESS");
            String aadharNumber = rs.getString("AADHAR_NUMBER");
            String panNumber = rs.getString("PAN_NUMBER");
            String zipcode = rs.getString("ZIPCODE");
            
            // Clean up customer ID
            if (customerId != null) {
                customerId = customerId.trim();
                if ("0".equals(customerId) || ".".equals(customerId)) {
                    customerId = "";
                }
            } else {
                customerId = "";
            }
            
            // Clean up customer address (returned from Fn_Get_Cust_address)
            if (customerAddress != null) {
                customerAddress = customerAddress.trim();
                if (".".equals(customerAddress) || customerAddress.isEmpty()) {
                    customerAddress = "";
                }
            } else {
                customerAddress = "";
            }
         
         	// Clean up Aadhar number
            if (aadharNumber != null) {
                aadharNumber = aadharNumber.trim();
                if (".".equals(aadharNumber)) {
                    aadharNumber = "";
                }
            } else {
                aadharNumber = "";
            }
            
         // Clean up PAN number
            if (panNumber != null) {
                panNumber = panNumber.trim();
                if ("0".equals(panNumber)) {
                    panNumber = "";
                }
            } else {
                panNumber = "";
            }
            
            // Clean up ZIP code 
            if (zipcode != null) {
                zipcode = zipcode.trim();
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
            out.print("\"customerId\": \"" + customerId + "\",");
            out.print("\"customerAddress\": \"" + customerAddress.replace("\"", "\\\"") + "\",");
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
