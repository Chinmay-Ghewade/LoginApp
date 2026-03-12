<%@ page import="java.sql.*, db.DBConnection, org.json.*" %>
<%@ page contentType="application/json; charset=UTF-8" %>
<%
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    String accountType = request.getParameter("accountType");
    
 
    System.out.println("=== GetClosingSequenceColumns DEBUG ===");
    System.out.println("Received accountType parameter: [" + accountType + "]");

    Connection con = null;
    PreparedStatement ps = null;
    ResultSet rs = null;
    
    try {
        con = DBConnection.getConnection();
        
        String query = "SELECT SR_NO, DISCRIPTATION, SEQUENCE_NO, COLUMN_NAME, ACCOUNT_TYPE " +
                       "FROM HEADOFFICE.CLOUSING_SEQ ";
        
        if (accountType != null && !accountType.trim().isEmpty()) {
            query += "WHERE UPPER(ACCOUNT_TYPE) = UPPER(?) ";
        }
        
        query += "ORDER BY SEQUENCE_NO";
        
 
        System.out.println("Query: " + query);
        
        ps = con.prepareStatement(query);
        
        if (accountType != null && !accountType.trim().isEmpty()) {
            ps.setString(1, accountType.trim());
            System.out.println("Set parameter 1 to: [" + accountType.trim() + "]");
        }
        
        rs = ps.executeQuery();
        
        JSONObject jsonResponse = new JSONObject();
        jsonResponse.put("success", true);
        
        JSONArray columnsArray = new JSONArray();
        
        int rowCount = 0;
        while (rs.next()) {
            rowCount++;
            JSONObject column = new JSONObject();
            column.put("srNo", rs.getInt("SR_NO"));
            
            String description = rs.getString("DISCRIPTATION");
            String columnName = rs.getString("COLUMN_NAME");
            String dbAccountType = rs.getString("ACCOUNT_TYPE");
            
 
            System.out.println("Row " + rowCount + ": ACCOUNT_TYPE=[" + dbAccountType + "], COLUMN_NAME=[" + columnName + "]");
            
            // Skip rows with null or empty column names
            if (columnName == null || columnName.trim().isEmpty()) {
                continue;
            }
            
            column.put("description", description != null ? description : "");
            column.put("sequenceNo", rs.getInt("SEQUENCE_NO"));
            column.put("columnName", columnName.trim());
            
            columnsArray.put(column);
        }
        

        System.out.println("Total rows found: " + rowCount);
        System.out.println("Valid columns after filtering: " + columnsArray.length());
        System.out.println("=====================================");
        
        jsonResponse.put("columns", columnsArray);
        jsonResponse.put("count", columnsArray.length());
        
        out.print(jsonResponse.toString());
        
    } catch (SQLException e) {
        e.printStackTrace();
        System.out.println("SQL Error: " + e.getMessage());
        
        JSONObject errorResponse = new JSONObject();
        errorResponse.put("success", false);
        errorResponse.put("error", "Database error: " + e.getMessage());
        errorResponse.put("columns", new JSONArray());
        
        out.print(errorResponse.toString());
        
    } finally {
        if (rs != null) try { rs.close(); } catch(SQLException e) { e.printStackTrace(); }
        if (ps != null) try { ps.close(); } catch(SQLException e) { e.printStackTrace(); }
        if (con != null) try { con.close(); } catch(SQLException e) { e.printStackTrace(); }
    }
%>