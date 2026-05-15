package servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Types;
import java.util.Date;
import java.util.Enumeration;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.json.JSONObject;

import db.DBConnection;

@MultipartConfig
@WebServlet("/RtgsServlet")
public class RtgsServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        PrintWriter out = response.getWriter();
        JSONObject jsonResponse = new JSONObject();

        Connection con = null;

        try {

            // =========================================================
            // DEBUG PARAMETERS
            // =========================================================


            Enumeration<String> paramNames = request.getParameterNames();

            while (paramNames.hasMoreElements()) {

                String paramName = paramNames.nextElement();
                String paramValue = request.getParameter(paramName);

                System.out.println(paramName + " = " + paramValue);
            }

            // =========================================================
            // SESSION
            // =========================================================

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

            System.out.println("branchCode = " + branchCode);
            System.out.println("userId = " + userId);
            System.out.println("workingDate = " + workingDate);

            if (workingDate == null) {

                jsonResponse.put("success", false);
                jsonResponse.put("message", "Working date missing in session");

                out.print(jsonResponse.toString());
                return;
            }

            // =========================================================
            // FORM PARAMETERS
            // =========================================================

            String transactionMode = request.getParameter("transactionMode");
            String transactionType = request.getParameter("transactionType");

            // REMITTER

            String remitterAccountCode = request.getParameter("accountCode");
            String remitterIfscCode = request.getParameter("remittingIfscCode");
            String remitterName = request.getParameter("accountName");

            // ADDRESS

            String remitterAddress1;
            String remitterAddress2;
            String remitterAddress3;

            if ("Cash".equals(transactionMode)) {

                remitterAddress1 = request.getParameter("cashAddress1");
                remitterAddress2 = request.getParameter("cashAddress2");
                remitterAddress3 = request.getParameter("cashAddress3");

            } else {

                remitterAddress1 = request.getParameter("address1");
                remitterAddress2 = request.getParameter("address2");
                remitterAddress3 = request.getParameter("address3");
            }

            // CONTACTS

            String appContactNoStr = request.getParameter("appContactNo");
            String residenceNoStr = request.getParameter("residenceNo");
            String officeNoStr = request.getParameter("officeNo");

            String remitterEmailId = request.getParameter("appEmailId");

            // BENEFICIARY

            String beneAccountCode = request.getParameter("beneficiaryAccountCode");
            String beneAccountName = request.getParameter("beneficiaryName");
            String beneIfscCode = request.getParameter("ifscCode");

            String beneAddress1 = request.getParameter("beneficiaryAddress1");
            String beneAddress2 = request.getParameter("beneficiaryAddress2");
            String beneCity = request.getParameter("beneficiaryCity");
            String beneState = request.getParameter("beneficiaryState");

            String beneBankBranchName = request.getParameter("ifscBranchName");

            String beneMobileStr = request.getParameter("beneficiaryMobile");
            String beneResidenceStr = request.getParameter("beneficiaryResidence");
            String beneOfficeStr = request.getParameter("beneficiaryOffice");

            // PAYMENT

            String amountStr = request.getParameter("remittingAmount");
            String chargesStr = request.getParameter("applicableCharges");
            String serviceTaxStr = request.getParameter("serviceTax");

            String senderToReceiverInfo = request.getParameter("SenderToReceiver");

            // CHEQUE

            String chequeType = request.getParameter("chequeType");
            String chequeSeries = request.getParameter("chequeSeries");
            String chequeNumberStr = request.getParameter("chequeNumber");
            String chequeDate = request.getParameter("chequeDate");

            // =========================================================
            // VALIDATION
            // =========================================================

            if (isEmpty(remitterAccountCode)
                    || isEmpty(beneAccountCode)
                    || isEmpty(beneAccountName)
                    || isEmpty(beneIfscCode)
                    || isEmpty(amountStr)) {

                jsonResponse.put("success", false);
                jsonResponse.put("message", "Mandatory fields missing");

                out.print(jsonResponse.toString());
                return;
            }

            // =========================================================
            // NORMALIZE NULLS
            // =========================================================

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

            senderToReceiverInfo =
                    isEmpty(senderToReceiverInfo) ? null : senderToReceiverInfo;

            // =========================================================
            // AMOUNT PARSE
            // =========================================================

            BigDecimal amount;
            BigDecimal charges;
            BigDecimal serviceTax;

            try {

                amount = new BigDecimal(amountStr);

                charges =
                        new BigDecimal(
                                chargesStr == null || chargesStr.trim().isEmpty()
                                        ? "0"
                                        : chargesStr);

                serviceTax =
                        new BigDecimal(
                                serviceTaxStr == null || serviceTaxStr.trim().isEmpty()
                                        ? "0"
                                        : serviceTaxStr);

            } catch (Exception e) {

                jsonResponse.put("success", false);
                jsonResponse.put("message", "Invalid amount");

                out.print(jsonResponse.toString());
                return;
            }

            // =========================================================
            // PHONE NUMBERS
            // =========================================================

            Long remitterMobile = parsePhoneNumber(appContactNoStr);
            Long remitterResidence = parsePhoneNumber(residenceNoStr);
            Long remitterOffice = parsePhoneNumber(officeNoStr);

            Long beneMobile = parsePhoneNumber(beneMobileStr);
            Long beneResidence = parsePhoneNumber(beneResidenceStr);
            Long beneOffice = parsePhoneNumber(beneOfficeStr);

            // =========================================================
            // CHEQUE NUMBER
            // =========================================================

            Long chequeNumber = null;

            if (!isEmpty(chequeNumberStr)) {

                try {

                    chequeNumber = Long.parseLong(chequeNumberStr);

                } catch (Exception e) {

                    chequeNumber = null;
                }
            }

            // =========================================================
            // DB
            // =========================================================

            con = DBConnection.getConnection();

            con.setAutoCommit(false);

            long scrollNumber = getNextScrollNumber(con);

            String messageType = mapTransactionType(transactionType);

            String trnType =
                    "Transfer".equals(transactionMode) ? "O" : "T";

            System.out.println("OUTWARD_DATE = " + workingDate);

            // =========================================================
            // INSERT
            // =========================================================

            insertRtgsOutward(
                    con,
                    branchCode,
                    workingDate,
                    scrollNumber,
                    remitterAccountCode,
                    remitterIfscCode,
                    remitterName,
                    remitterAddress1,
                    remitterAddress2,
                    remitterAddress3,
                    remitterMobile,
                    remitterResidence,
                    remitterOffice,
                    remitterEmailId,
                    beneAccountCode,
                    beneAccountName,
                    beneIfscCode,
                    beneAddress1,
                    beneAddress2,
                    beneCity,
                    beneState,
                    beneMobile,
                    beneResidence,
                    beneOffice,
                    amount,
                    charges,
                    serviceTax,
                    senderToReceiverInfo,
                    beneBankBranchName,
                    chequeType,
                    chequeSeries,
                    chequeNumber,
                    chequeDate,
                    messageType,
                    trnType,
                    userId);

            con.commit();

            jsonResponse.put("success", true);
            jsonResponse.put("message", "RTGS saved successfully");
            jsonResponse.put("scrollNumber", scrollNumber);

            out.print(jsonResponse.toString());

        } catch (Exception e) {

            if (con != null) {

                try {
                    con.rollback();
                } catch (Exception ex) {
                }
            }

            e.printStackTrace();

            jsonResponse.put("success", false);
            jsonResponse.put("message", e.getMessage());

            out.print(jsonResponse.toString());

        } finally {

            if (con != null) {

                try {

                    con.setAutoCommit(true);
                    con.close();

                } catch (Exception e) {
                }
            }
        }
    }

    // =========================================================
    // INSERT METHOD
    // =========================================================

    private void insertRtgsOutward(
            Connection con,
            String branchCode,
            Date workingDate,
            long scrollNumber,
            String remitterAccountCode,
            String remitterIfscCode,
            String remitterName,
            String remitterAddress1,
            String remitterAddress2,
            String remitterAddress3,
            Long remitterMobile,
            Long remitterResidence,
            Long remitterOffice,
            String remitterEmailId,
            String beneAccountCode,
            String beneAccountName,
            String beneIfscCode,
            String beneAddress1,
            String beneAddress2,
            String beneCity,
            String beneState,
            Long beneMobile,
            Long beneResidence,
            Long beneOffice,
            BigDecimal amount,
            BigDecimal charges,
            BigDecimal serviceTax,
            String senderToReceiverInfo,
            String beneBankBranchName,
            String chequeType,
            String chequeSeries,
            Long chequeNumber,
            String chequeDate,
            String messageType,
            String trnType,
            String userId)
            throws SQLException {

        PreparedStatement ps = null;

        try {

            String query =
                    "INSERT INTO HISTORY.RTGS_OUTWARD ("
                            + "REMITTER_ACCOUNT_CODE, REMITTER_IFCS_CODE, REMITTER_NAME, "
                            + "REMITTER_ADDRESS_1, REMITTER_ADDRESS_2, REMITTER_ADDRESS_3, "
                            + "REMITTER_CONTACT_NUMBER_M, REMITTER_CONTACT_NUMBER_R, REMITTER_CONTACT_NUMBER_O, "
                            + "REMITTER_EMAIL_ID, "
                            + "BENE_ACCOUNT_CODE, BENE_ACCOUNT_NAME, BENE_IFSC_CODE, "
                            + "BENE_ADDRESS_1, BENE_ADDRESS_2, BENE_ADDRESS_3, BENE_ADDRESS_4, "
                            + "BENE_CONTACT_NUMBER_M, BENE_CONTACT_NUMBER_R, BENE_CONTACT_NUMBER_O, "
                            + "AMOUNT, CAHRGES, SERVICE_TAX, SENDER_TO_RECE_INFO, "
                            + "UPLOAD_DATE, OUTWARD_DATE, TRANSACTION_STATUS, IS_FILE_UPLOAD, "
                            + "SCROLL_NUMBER, BENE_BANK_BRANCH_NAME, BRANCH_CODE, "
                            + "USER_ID, CREATED_DATE, MODIFIED_DATE, "
                            + "MESSAGE_TYPE, TRN_TYPE, "
                            + "CHEQUE_TYPE, CHEQUESERIES, CHEQUENUMBER, CHEQUEDATE"
                            + ") VALUES ("
                            + "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "
                            + "?, ?, ?, ?, ?, ?, ?, ?, ?, ?, "
                            + "?, ?, ?, ?, "
                            + "SYSDATE, ?, 'E', 'N', "
                            + "?, ?, ?, "
                            + "?, SYSDATE, SYSDATE, "
                            + "?, ?, "
                            + "?, ?, ?, ?"
                            + ")";

            ps = con.prepareStatement(query);

            int p = 1;

            // =====================================================
            // REMITTER
            // =====================================================

            ps.setString(p++, remitterAccountCode);
            ps.setString(p++, remitterIfscCode);
            ps.setString(p++, remitterName);

            ps.setString(p++, remitterAddress1);
            ps.setString(p++, remitterAddress2);
            ps.setString(p++, remitterAddress3);

            setLongOrNull(ps, p++, remitterMobile);
            setLongOrNull(ps, p++, remitterResidence);
            setLongOrNull(ps, p++, remitterOffice);

            ps.setString(p++, remitterEmailId);

            // =====================================================
            // BENEFICIARY
            // =====================================================

            ps.setString(p++, beneAccountCode);
            ps.setString(p++, beneAccountName);
            ps.setString(p++, beneIfscCode);

            ps.setString(p++, beneAddress1);
            ps.setString(p++, beneAddress2);
            ps.setString(p++, beneCity);
            ps.setString(p++, beneState);

            setLongOrNull(ps, p++, beneMobile);
            setLongOrNull(ps, p++, beneResidence);
            setLongOrNull(ps, p++, beneOffice);

            // =====================================================
            // AMOUNT
            // =====================================================

            ps.setBigDecimal(p++, amount);
            ps.setBigDecimal(p++, charges);
            ps.setBigDecimal(p++, serviceTax);

            ps.setString(p++, senderToReceiverInfo);

            // =====================================================
            // OUTWARD DATE
            // =====================================================

            ps.setDate(
                    p++,
                    new java.sql.Date(workingDate.getTime()));

            // =====================================================
            // OTHER
            // =====================================================

            ps.setLong(p++, scrollNumber);

            ps.setString(p++, beneBankBranchName);
            ps.setString(p++, branchCode);

            ps.setString(p++, userId);

            ps.setString(p++, messageType);
            ps.setString(p++, trnType);

            // =====================================================
            // CHEQUE
            // =====================================================

            ps.setString(p++, chequeType);
            ps.setString(p++, chequeSeries);

            setLongOrNull(ps, p++, chequeNumber);

            setDateOrNull(ps, p++, chequeDate);

            System.out.println("Executing INSERT...");

            int rows = ps.executeUpdate();

            System.out.println("Rows inserted = " + rows);

            if (rows == 0) {

                throw new SQLException("Insert failed");
            }

        } finally {

            if (ps != null) {

                try {
                    ps.close();
                } catch (Exception e) {
                }
            }
        }
    }

    // =========================================================
    // SCROLL NUMBER
    // =========================================================

    private long getNextScrollNumber(Connection con)
            throws SQLException {

        PreparedStatement ps = null;
        ResultSet rs = null;

        try {

            ps =
                    con.prepareStatement(
                            "SELECT NEXT_SCROLL_NO.NEXTVAL FROM DUAL");

            rs = ps.executeQuery();

            if (rs.next()) {

                return rs.getLong(1);
            }

            throw new SQLException("Sequence failed");

        } finally {

            if (rs != null) {
                rs.close();
            }

            if (ps != null) {
                ps.close();
            }
        }
    }

    // =========================================================
    // MAP TYPE
    // =========================================================

    private String mapTransactionType(String transactionType) {

        if ("RTGS".equals(transactionType))
            return "RTS";

        if ("NEFT".equals(transactionType))
            return "NEF";

        if ("ThirdParty".equals(transactionType))
            return "TP3";

        return "RTS";
    }

    // =========================================================
    // UTIL METHODS
    // =========================================================

    private boolean isEmpty(String str) {

        return str == null || str.trim().isEmpty();
    }

    private Long parsePhoneNumber(String phone) {

        if (isEmpty(phone))
            return null;

        try {

            String digits = phone.replaceAll("\\D", "");

            return digits.isEmpty()
                    ? null
                    : Long.parseLong(digits);

        } catch (Exception e) {

            return null;
        }
    }

    private void setLongOrNull(
            PreparedStatement ps,
            int idx,
            Long value)
            throws SQLException {

        if (value == null) {

            ps.setNull(idx, Types.NUMERIC);

        } else {

            ps.setLong(idx, value);
        }
    }

    private void setDateOrNull(
            PreparedStatement ps,
            int idx,
            String dateStr)
            throws SQLException {

        if (isEmpty(dateStr)) {

            ps.setNull(idx, Types.DATE);

        } else {

            ps.setDate(
                    idx,
                    java.sql.Date.valueOf(dateStr));
        }
    }

    // =========================================================
    // GET
    // =========================================================

    @Override
    protected void doGet(
            HttpServletRequest request,
            HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("application/json");

        response.getWriter().print(
                "{\"error\":\"GET not supported. Use POST.\"}");
    }
}