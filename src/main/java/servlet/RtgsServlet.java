package servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.text.SimpleDateFormat;
import java.util.Date;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONObject;

import db.DBConnection;

/**
 * Servlet for saving RTGS Outward transactions
 * Saves data to HISTORY.RTGS_OUTWARD table
 * Generates scroll number from NEXT_SCROLL_NO sequence
 * Returns success response with scroll number for modal display
 */
@WebServlet("/RtgsServlet")
public class RtgsServlet extends HttpServlet {
    private static final long serialVersionUID = 1L;
    
    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        response.setHeader("Pragma", "no-cache");
        response.setDateHeader("Expires", 0);
        
        PrintWriter out = response.getWriter();
        JSONObject jsonResponse = new JSONObject();
        
        Connection con = null;
        
        try {
            // Get session
            HttpSession session = request.getSession(false);
            if (session == null || session.getAttribute("branchCode") == null) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Session expired. Please login again.");
                out.print(jsonResponse.toString());
                return;
            }
            
            String branchCode = (String) session.getAttribute("branchCode");
            String userId = (String) session.getAttribute("userId");
            Date workingDate = (Date) session.getAttribute("workingDate");
            
            if (workingDate == null) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Working date not found in session");
                out.print(jsonResponse.toString());
                return;
            }
            
            // Get form parameters
            String transactionMode = request.getParameter("transactionMode");  // Transfer/Cash
            String transactionType = request.getParameter("transactionType");  // RTGS/NEFT/ThirdParty
            
            // ===== REMITTER DETAILS =====
            String remitterAccountCode = request.getParameter("accountCode");
            String remitterIfscCode = request.getParameter("remittingIfscCode");
            String remitterName = request.getParameter("accountName");
            
            // Address - depends on mode
            String remitterAddress1, remitterAddress2, remitterAddress3;
            if ("Cash".equals(transactionMode)) {
                remitterAddress1 = request.getParameter("cashAddress1");
                remitterAddress2 = request.getParameter("cashAddress2");
                remitterAddress3 = request.getParameter("cashAddress3");
            } else {
                remitterAddress1 = request.getParameter("address1");
                remitterAddress2 = request.getParameter("address2");
                remitterAddress3 = request.getParameter("address3");
            }
            
            // Contact numbers
            String appContactNoStr = request.getParameter("appContactNo");
            String residenceNoStr = request.getParameter("residenceNo");
            String officeNoStr = request.getParameter("officeNo");
            String remitterEmailId = request.getParameter("appEmailId");
            
            // ===== BENEFICIARY DETAILS =====
            String beneAccountCode = request.getParameter("beneficiaryAccountCode");
            String beneAccountName = request.getParameter("beneficiaryName");
            String beneIfscCode = request.getParameter("ifscCode");
            String beneAddress1 = request.getParameter("beneficiaryAddress1");
            String beneAddress2 = request.getParameter("beneficiaryAddress2");
            String beneCity = request.getParameter("beneficiaryCity");
            String beneState = request.getParameter("beneficiaryState");
            String beneBankBranchName = request.getParameter("ifscBranchName");
            
            // Beneficiary contact numbers
            String beneMobileStr = request.getParameter("beneficiaryMobile");
            String beneResidenceStr = request.getParameter("beneficiaryResidence");
            String beneOfficeStr = request.getParameter("beneficiaryOffice");
            
            // ===== PAYMENT DETAILS =====
            String amountStr = request.getParameter("remittingAmount");
            String chargesStr = request.getParameter("applicableCharges");
            String serviceTaxStr = request.getParameter("serviceTax");
            String senderToReceiverInfo = request.getParameter("SenderToReceiver");
            
            // ===== CHEQUE DETAILS =====
            String chequeType = request.getParameter("chequeType");
            String chequeSeries = request.getParameter("chequeSeries");
            String chequeNumberStr = request.getParameter("chequeNumber");
            String chequeDate = request.getParameter("chequeDate");
            
            // Normalize empty strings to null
            remitterIfscCode = isEmpty(remitterIfscCode) ? null : remitterIfscCode;
            remitterAddress1 = isEmpty(remitterAddress1) ? null : remitterAddress1;
            remitterAddress2 = isEmpty(remitterAddress2) ? null : remitterAddress2;
            remitterAddress3 = isEmpty(remitterAddress3) ? null : remitterAddress3;
            remitterEmailId = isEmpty(remitterEmailId) ? null : remitterEmailId;
            beneAddress1 = isEmpty(beneAddress1) ? null : beneAddress1;
            beneAddress2 = isEmpty(beneAddress2) ? null : beneAddress2;
            beneCity = isEmpty(beneCity) ? null : beneCity;
            beneState = isEmpty(beneState) ? null : beneState;
            beneBankBranchName = isEmpty(beneBankBranchName) ? null : beneBankBranchName;
            chequeType = isEmpty(chequeType) ? null : chequeType;
            chequeSeries = isEmpty(chequeSeries) ? null : chequeSeries;
            chequeDate = isEmpty(chequeDate) ? null : chequeDate;
            senderToReceiverInfo = isEmpty(senderToReceiverInfo) ? null : senderToReceiverInfo;
            
            // Validate required fields
            if (isEmpty(remitterAccountCode) || isEmpty(beneAccountCode) || 
                isEmpty(beneAccountName) || isEmpty(beneIfscCode) || isEmpty(amountStr)) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Missing required fields: Account Code, Beneficiary Name, IFSC Code, and Amount are mandatory.");
                out.print(jsonResponse.toString());
                return;
            }
            
            // Parse amounts
            BigDecimal amount, charges, serviceTax;
            try {
                amount = new BigDecimal(amountStr.isEmpty() ? "0" : amountStr);
                charges = new BigDecimal(chargesStr == null || chargesStr.isEmpty() ? "0" : chargesStr);
                serviceTax = new BigDecimal(serviceTaxStr == null || serviceTaxStr.isEmpty() ? "0" : serviceTaxStr);
                
                if (amount.compareTo(BigDecimal.ZERO) <= 0) {
                    jsonResponse.put("success", false);
                    jsonResponse.put("message", "Amount must be greater than zero.");
                    out.print(jsonResponse.toString());
                    return;
                }
            } catch (NumberFormatException e) {
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Invalid amount format.");
                out.print(jsonResponse.toString());
                return;
            }
            
            // Parse phone numbers (remove non-digits, convert to Long)
            Long remitterMobile = parsePhoneNumber(appContactNoStr);
            Long remitterResidence = parsePhoneNumber(residenceNoStr);
            Long remitterOffice = parsePhoneNumber(officeNoStr);
            Long beneMobile = parsePhoneNumber(beneMobileStr);
            Long beneResidence = parsePhoneNumber(beneResidenceStr);
            Long beneOffice = parsePhoneNumber(beneOfficeStr);
            
            // Parse cheque number
            Long chequeNumber = null;
            if (!isEmpty(chequeNumberStr)) {
                try {
                    chequeNumber = Long.parseLong(chequeNumberStr);
                } catch (NumberFormatException e) {
                    // Leave as null if not valid
                }
            }
            
            // Get database connection
            con = DBConnection.getConnection();
            con.setAutoCommit(false);
            
            // Get scroll number from sequence
            long scrollNumber = getNextScrollNumber(con);
            
            // Determine MESSAGE_TYPE from transactionType
            String messageType = mapTransactionType(transactionType);
            
            // Determine TRN_TYPE from transactionMode
            String trnType = "Transfer".equals(transactionMode) ? "O" : "T";
            
            // Insert RTGS record
            insertRtgsOutward(con, branchCode, workingDate, scrollNumber, 
                            remitterAccountCode, remitterIfscCode, remitterName,
                            remitterAddress1, remitterAddress2, remitterAddress3,
                            remitterMobile, remitterResidence, remitterOffice, remitterEmailId,
                            beneAccountCode, beneAccountName, beneIfscCode,
                            beneAddress1, beneAddress2, beneCity, beneState,
                            beneMobile, beneResidence, beneOffice,
                            amount, charges, serviceTax, senderToReceiverInfo,
                            beneBankBranchName, chequeType, chequeSeries, chequeNumber, chequeDate,
                            messageType, trnType, userId);
            
            // Commit transaction
            con.commit();
            
            // Return success response
            jsonResponse.put("success", true);
            jsonResponse.put("message", "RTGS entry saved successfully");
            jsonResponse.put("scrollNumber", scrollNumber);
            jsonResponse.put("beneficiaryName", beneAccountName);
            jsonResponse.put("totalAmount", amount.toString());
            
            out.print(jsonResponse.toString());
            
        } catch (SQLException e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            out.print(jsonResponse.toString());
            
        } catch (Exception e) {
            if (con != null) {
                try { con.rollback(); } catch (SQLException ex) { ex.printStackTrace(); }
            }
            e.printStackTrace();
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Server error: " + e.getMessage());
            out.print(jsonResponse.toString());
            
        } finally {
            if (con != null) {
                try {
                    con.setAutoCommit(true);
                    con.close();
                } catch (SQLException e) {
                    e.printStackTrace();
                }
            }
        }
    }
    
    /**
     * Insert RTGS Outward record
     */
    private void insertRtgsOutward(Connection con, String branchCode, Date workingDate,
                                  long scrollNumber, String remitterAccountCode,
                                  String remitterIfscCode, String remitterName,
                                  String remitterAddress1, String remitterAddress2,
                                  String remitterAddress3, Long remitterMobile,
                                  Long remitterResidence, Long remitterOffice,
                                  String remitterEmailId, String beneAccountCode,
                                  String beneAccountName, String beneIfscCode,
                                  String beneAddress1, String beneAddress2,
                                  String beneCity, String beneState, Long beneMobile,
                                  Long beneResidence, Long beneOffice,
                                  BigDecimal amount, BigDecimal charges, BigDecimal serviceTax,
                                  String senderToReceiverInfo, String beneBankBranchName,
                                  String chequeType, String chequeSeries, Long chequeNumber,
                                  String chequeDate, String messageType, String trnType,
                                  String userId) throws SQLException {
        
        PreparedStatement ps = null;
        
        try {
            String query = "INSERT INTO HISTORY.RTGS_OUTWARD (" +
                          "REMITTER_ACCOUNT_CODE, REMITTER_IFCS_CODE, REMITTER_NAME, " +
                          "REMITTER_ADDRESS_1, REMITTER_ADDRESS_2, REMITTER_ADDRESS_3, " +
                          "REMITTER_CONTACT_NUMBER_M, REMITTER_CONTACT_NUMBER_R, " +
                          "REMITTER_CONTACT_NUMBER_O, REMITTER_EMAIL_ID, " +
                          "BENE_ACCOUNT_CODE, BENE_ACCOUNT_NAME, BENE_IFSC_CODE, " +
                          "BENE_ADDRESS_1, BENE_ADDRESS_2, BENE_ADDRESS_3, BENE_ADDRESS_4, " +
                          "BENE_CONTACT_NUMBER_M, BENE_CONTACT_NUMBER_R, BENE_CONTACT_NUMBER_O, " +
                          "AMOUNT, CAHRGES, SERVICE_TAX, SENDER_TO_RECE_INFO, " +
                          "UPLOAD_DATE, TRANSACTION_STATUS, IS_FILE_UPLOAD, " +
                          "SCROLL_NUMBER, BENE_BANK_BRANCH_NAME, BRANCH_CODE, " +
                          "USER_ID, CREATED_DATE, MODIFIED_DATE, " +
                          "MESSAGE_TYPE, TRN_TYPE, CHEQUE_TYPE, CHEQUESERIES, " +
                          "CHEQUENUMBER, CHEQUEDATE " +
                          ") VALUES (" +
                          "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, " +
                          "?, ?, ?, ?, SYSDATE, 'E', 'N', ?, ?, ?, ?, SYSDATE, SYSDATE, " +
                          "?, ?, ?, ?, ?, ?" +
                          ")";
            
            ps = con.prepareStatement(query);
            
            int paramIndex = 1;
            
            // Remitter details
            ps.setString(paramIndex++, remitterAccountCode);
            ps.setString(paramIndex++, remitterIfscCode);
            ps.setString(paramIndex++, remitterName);
            ps.setString(paramIndex++, remitterAddress1);
            ps.setString(paramIndex++, remitterAddress2);
            ps.setString(paramIndex++, remitterAddress3);
            setLongOrNull(ps, paramIndex++, remitterMobile);
            setLongOrNull(ps, paramIndex++, remitterResidence);
            setLongOrNull(ps, paramIndex++, remitterOffice);
            ps.setString(paramIndex++, remitterEmailId);
            
            // Beneficiary details
            ps.setString(paramIndex++, beneAccountCode);
            ps.setString(paramIndex++, beneAccountName);
            ps.setString(paramIndex++, beneIfscCode);
            ps.setString(paramIndex++, beneAddress1);
            ps.setString(paramIndex++, beneAddress2);
            ps.setString(paramIndex++, beneCity);  // BENE_ADDRESS_3
            ps.setString(paramIndex++, beneState);  // BENE_ADDRESS_4
            setLongOrNull(ps, paramIndex++, beneMobile);
            setLongOrNull(ps, paramIndex++, beneResidence);
            setLongOrNull(ps, paramIndex++, beneOffice);
            
            // Payment details
            ps.setBigDecimal(paramIndex++, amount);
            ps.setBigDecimal(paramIndex++, charges);
            ps.setBigDecimal(paramIndex++, serviceTax);
            ps.setString(paramIndex++, senderToReceiverInfo);
            
            // Auto-filled fields
            ps.setLong(paramIndex++, scrollNumber);
            ps.setString(paramIndex++, beneBankBranchName);
            ps.setString(paramIndex++, branchCode);
            ps.setString(paramIndex++, userId);
            
            // Transaction types
            ps.setString(paramIndex++, messageType);
            ps.setString(paramIndex++, trnType);
            
            // Cheque details
            ps.setString(paramIndex++, chequeType);
            ps.setString(paramIndex++, chequeSeries);
            setLongOrNull(ps, paramIndex++, chequeNumber);
            setDateOrNull(ps, paramIndex++, chequeDate);
            
            int rowsInserted = ps.executeUpdate();
            
            if (rowsInserted == 0) {
                throw new SQLException("Failed to insert RTGS outward record");
            }
            
        } finally {
            if (ps != null) {
                try { ps.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }
    
    /**
     * Get next scroll number from sequence
     */
    private long getNextScrollNumber(Connection con) throws SQLException {
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            String query = "SELECT NEXT_SCROLL_NO.NEXTVAL FROM DUAL";
            ps = con.prepareStatement(query);
            rs = ps.executeQuery();
            
            if (rs.next()) {
                return rs.getLong(1);
            }
            
            throw new SQLException("Failed to get next scroll number from sequence");
            
        } finally {
            if (rs != null) {
                try { rs.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
            if (ps != null) {
                try { ps.close(); } catch (SQLException e) { e.printStackTrace(); }
            }
        }
    }
    
    /**
     * Map transaction type to 3-character MESSAGE_TYPE code
     */
    private String mapTransactionType(String transactionType) {
        if ("RTGS".equals(transactionType)) {
            return "RTS";
        } else if ("NEFT".equals(transactionType)) {
            return "NEF";
        } else if ("ThirdParty".equals(transactionType)) {
            return "TP3";
        }
        return "RTS";  // Default
    }
    
    /**
     * Check if string is empty or null
     */
    private boolean isEmpty(String str) {
        return str == null || str.trim().isEmpty();
    }
    
    /**
     * Parse phone number - remove non-digits and convert to Long
     */
    private Long parsePhoneNumber(String phone) {
        if (isEmpty(phone)) {
            return null;
        }
        try {
            String digits = phone.replaceAll("\\D", "");
            if (digits.isEmpty()) {
                return null;
            }
            return Long.parseLong(digits);
        } catch (NumberFormatException e) {
            return null;
        }
    }
    
    /**
     * Set Long value or NULL in prepared statement
     */
    private void setLongOrNull(PreparedStatement ps, int paramIndex, Long value) throws SQLException {
        if (value == null) {
            ps.setNull(paramIndex, Types.NUMERIC);
        } else {
            ps.setLong(paramIndex, value);
        }
    }
    
    /**
     * Set Date value or NULL in prepared statement
     */
    private void setDateOrNull(PreparedStatement ps, int paramIndex, String dateStr) throws SQLException {
        if (isEmpty(dateStr)) {
            ps.setNull(paramIndex, Types.DATE);
        } else {
            ps.setDate(paramIndex, java.sql.Date.valueOf(dateStr));
        }
    }
    
    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        
        response.setContentType("application/json");
        PrintWriter out = response.getWriter();
        JSONObject jsonResponse = new JSONObject();
        
        jsonResponse.put("error", "GET method not supported. Use POST.");
        out.print(jsonResponse.toString());
    }
}