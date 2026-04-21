<%@ page import="java.sql.*, db.DBConnection" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    
    String branchCode = (String) session.getAttribute("branchCode");
    if (branchCode == null) {
        out.print("{\"error\": \"Not authenticated\"}");
        return;
    }
    
    // Get card type and identifier
    String cardType = request.getParameter("type");      // "dashboard", "view", "auth"
    String cardId = request.getParameter("id");          // Card identifier
    
    if (cardType == null || cardId == null) {
        out.print("{\"error\": \"Missing parameters\"}");
        return;
    }
    
    Connection conn = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        conn = DBConnection.getConnection();
        String value = "N/A";  // Default for missing/invalid data
        
        // Get working date from session
        Date workingDate = (Date) session.getAttribute("workingDate");
        
        switch(cardType.toLowerCase()) {
            case "dashboard":
                // Dashboard cards - use function calls
                ps = conn.prepareStatement(
                    "SELECT FUNCATION_NAME, PARAMITAR, TABLE_NAME, DESCRIPTION " +
                    "FROM GLOBALCONFIG.DASHBOARD " +
                    "WHERE SR_NUMBER = ? AND DESCRIPTION IS NOT NULL"
                );
                ps.setString(1, cardId);
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    String functionName = rs.getString("FUNCATION_NAME");
                    String parameters = rs.getString("PARAMITAR");
                    String tableName = rs.getString("TABLE_NAME");
                    
                    if (functionName != null && !functionName.trim().isEmpty()) {
                        value = executeCardFunction(conn, functionName, parameters, tableName, branchCode);
                    } else {
                        value = "N/A";
                    }
                } else {
                    value = "N/A";
                }
                break;
                
            case "view":
                // View page cards
                if ("total_accounts".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) as TOTAL " +
                        "FROM ACCOUNT.ACCOUNT " +
                        "WHERE SUBSTR(ACCOUNT_CODE, 1, 4) = ?"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt("TOTAL")) : "0";

                } else if ("all_customers".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) as TOTAL FROM CUSTOMER.CUSTOMER " +
                        "WHERE SUBSTR(CUSTOMER_ID, 1, 4) = ?"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt("TOTAL")) : "0";

                } else if ("all_users".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) as TOTAL FROM ACL.USERREGISTER " +
                        "WHERE BRANCH_CODE = ?"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt("TOTAL")) : "0";

                } else if ("maintenance_users".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) as TOTAL FROM ACL.USERREGISTER " +
                        "WHERE BRANCH_CODE = ? AND STATUS = 'E'"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt("TOTAL")) : "0";
                }
                break;
                
            case "reports":
                ps = conn.prepareStatement(
                    "SELECT FUNCATION_NAME, PARAMITAR, TABLE_NAME, DESCRIPTION " +
                    "FROM GLOBALCONFIG.REPORTS " +
                    "WHERE SR_NUMBER = ? AND DESCRIPTION IS NOT NULL"
                );
                ps.setString(1, cardId);
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    String functionName = rs.getString("FUNCATION_NAME");
                    String parameters = rs.getString("PARAMITAR");
                    String tableName = rs.getString("TABLE_NAME");
                    
                    if (functionName != null && !functionName.trim().isEmpty()) {
                        value = executeCardFunction(conn, functionName, parameters, tableName, branchCode);
                    } else {
                        value = "N/A";
                    }
                } else {
                    value = "N/A";
                }
                break;
                
            case "masters":
                ps = conn.prepareStatement(
                    "SELECT FUNCATION_NAME, PARAMITAR, TABLE_NAME, DESCRIPTION " +
                    "FROM GLOBALCONFIG.MASTERS " +
                    "WHERE SR_NUMBER = ? AND DESCRIPTION IS NOT NULL"
                );
                ps.setString(1, cardId);
                rs = ps.executeQuery();
                
                if (rs.next()) {
                    String functionName = rs.getString("FUNCATION_NAME");
                    String parameters = rs.getString("PARAMITAR");
                    String tableName = rs.getString("TABLE_NAME");
                    
                    if (functionName != null && !functionName.trim().isEmpty()) {
                        value = executeCardFunction(conn, functionName, parameters, tableName, branchCode);
                    } else {
                        value = "N/A";
                    }
                } else {
                    value = "N/A";
                }
                break;
                
            case "auth":
                // Authorization pending cards
                if ("pending_customers".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM CUSTOMERS " +
                        "WHERE BRANCH_CODE=? AND STATUS = 'P'"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";

                } else if ("pending_users".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM ACL.USERREGISTER " +
                        "WHERE BRANCH_CODE=? AND STATUS='E'"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";

                } else if ("pending_applications".equals(cardId)) {
                    if (workingDate != null) {
                        ps = conn.prepareStatement(
                            "SELECT COUNT(*) FROM APPLICATION.APPLICATION " +
                            "WHERE BRANCH_CODE=? AND STATUS = 'E' " +
                            "AND TRUNC(APPLICATIONDATE) = TRUNC(?)"
                        );
                        ps.setString(1, branchCode);
                        ps.setDate(2, workingDate);
                        rs = ps.executeQuery();
                        value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";
                    } else {
                        value = "N/A";
                    }

                } else if ("pending_masters".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM AUDITTRAIL.MASTER_AUDITTRAIL WHERE STATUS='E'"
                    );
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";

                } else if ("pending_txn_cash".equals(cardId)) {
                    if (workingDate != null) {
                        ps = conn.prepareStatement(
                            "SELECT COUNT(*) FROM TRANSACTION.DAILYSCROLL " +
                            "WHERE BRANCH_CODE = ? AND TRANSACTIONSTATUS = 'E' " +
                            "AND TRANSACTIONINDICATOR_CODE LIKE 'CS%' " +
                            "AND TRUNC(SCROLL_DATE) = TRUNC(?)"
                        );
                        ps.setString(1, branchCode);
                        ps.setDate(2, workingDate);
                        rs = ps.executeQuery();
                        value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";
                    } else {
                        value = "N/A";
                    }

                } else if ("pending_txn_transfer".equals(cardId)) {
                    if (workingDate != null) {
                        ps = conn.prepareStatement(
                            "SELECT COUNT(*) FROM TRANSACTION.DAILYSCROLL " +
                            "WHERE BRANCH_CODE = ? AND TRANSACTIONSTATUS = 'E' " +
                            "AND TRANSACTIONINDICATOR_CODE LIKE 'TR%' " +
                            "AND TRUNC(SCROLL_DATE) = TRUNC(?)"
                        );
                        ps.setString(1, branchCode);
                        ps.setDate(2, workingDate);
                        rs = ps.executeQuery();
                        value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";
                    } else {
                        value = "N/A";
                    }
                } else if ("pending_shares".equals(cardId)) {
                    ps = conn.prepareStatement(
                        "SELECT COUNT(*) FROM SHARES.CERTIFICATE_MASTER " +
                        "WHERE STATUS = 'E' " +
                        "AND NVL(BR_CODE, 'NULL') = NVL(?, 'NULL')"
                    );
                    ps.setString(1, branchCode);
                    rs = ps.executeQuery();
                    value = rs.next() ? String.valueOf(rs.getInt(1)) : "0";
                }
                break;

            default:
                out.print("{\"error\": \"Unknown card type\"}");
                return;
        }
        
        // Return success response
        out.print("{\"value\": \"" + value.replace("\"", "\\\"") + "\", \"status\": \"success\"}");
        
    } catch (Exception e) {
        e.printStackTrace();
        out.print("{\"error\": \"" + e.getMessage().replace("\"", "\\\"") + "\"}");
    } finally {
        try { if (rs != null) rs.close(); } catch (Exception ex) {}
        try { if (ps != null) ps.close(); } catch (Exception ex) {}
        try { if (conn != null) conn.close(); } catch (Exception ex) {}
    }
%>

<%!
    // Helper method to execute dashboard card functions - Returns raw database value
    private String executeCardFunction(Connection conn, String functionName, String parameters, 
                                      String tableName, String branchCode) 
                                      throws SQLException {
        
        if (functionName == null || functionName.trim().isEmpty()) {
            return "N/A";
        }
        
        // Parse parameters
        String[] params = parameters != null && !parameters.trim().isEmpty() 
                         ? parameters.split(",") 
                         : new String[0];
        
        // Build SQL with function call
        StringBuilder sql = new StringBuilder("SELECT ").append(functionName).append("(");
        
        int paramCount = 0;
        for (int i = 0; i < params.length; i++) {
            if (paramCount > 0) sql.append(", ");
            
            String param = params[i].trim().toUpperCase();
            if (param.equals("DATE")) {
                sql.append("SYSDATE");
                paramCount++;
            } else if (param.equals("BRANCH")) {
                sql.append("?");
                paramCount++;
            } else {
                sql.append("?");
                paramCount++;
            }
        }
        sql.append(") FROM DUAL");
        
        PreparedStatement ps = null;
        ResultSet rs = null;
        
        try {
            ps = conn.prepareStatement(sql.toString());
            
            // Set parameters
            int paramIndex = 1;
            for (int i = 0; i < params.length; i++) {
                String param = params[i].trim().toUpperCase();
                if (!param.equals("DATE")) {
                    if (param.equals("BRANCH")) {
                        ps.setString(paramIndex++, branchCode);
                    } else {
                        ps.setString(paramIndex++, params[i].trim());
                    }
                }
            }
            
            rs = ps.executeQuery();
            if (rs.next()) {
                String result = rs.getString(1);
                return (result == null || result.trim().isEmpty()) ? "0" : result.trim();
            }
            
            return "0";
            
        } catch (SQLException e) {
            System.err.println("Error executing function: " + functionName);
            e.printStackTrace();
            return "Pending";
        } finally {
            try { if (rs != null) rs.close(); } catch (Exception ex) {}
            try { if (ps != null) ps.close(); } catch (Exception ex) {}
        }
    }
%>
