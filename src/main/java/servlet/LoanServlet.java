package servlet;

import db.DBConnection;
import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Date;
import java.sql.Timestamp;
import java.sql.Types;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

@WebServlet("/OpenAccount/LoanServlet")
public class LoanServlet extends HttpServlet {

    // ========= Utility methods =========

    private String generateApplicationNumber(Connection conn, String branchCode) throws Exception {
        String branchPrefix = String.format("%04d", Integer.parseInt(branchCode));

        String sql =
            "SELECT MAX(TO_NUMBER(SUBSTR(APPLICATION_NUMBER, 5, 10))) " +
            "FROM APPLICATION.APPLICATION " +
            "WHERE LENGTH(APPLICATION_NUMBER) = 14";

        PreparedStatement pstmt = conn.prepareStatement(sql);
        ResultSet rs = pstmt.executeQuery();

        long nextSeq = 1;
        if (rs.next() && rs.getLong(1) > 0) {
            nextSeq = rs.getLong(1) + 1;
        }
        rs.close();
        pstmt.close();

        String applicationNumber = branchPrefix + String.format("%010d", nextSeq);

        String checkSQL = "SELECT COUNT(*) FROM APPLICATION.APPLICATION WHERE APPLICATION_NUMBER = ?";
        PreparedStatement checkStmt = conn.prepareStatement(checkSQL);
        int attempts = 0;
        while (attempts < 100) {
            checkStmt.setString(1, applicationNumber);
            ResultSet checkRs = checkStmt.executeQuery();
            if (checkRs.next() && checkRs.getInt(1) > 0) {
                nextSeq++;
                applicationNumber = branchPrefix + String.format("%010d", nextSeq);
                checkRs.close();
                attempts++;
            } else {
                checkRs.close();
                break;
            }
        }
        checkStmt.close();

        if (attempts >= 100) {
            throw new Exception("Failed to generate unique APPLICATION_NUMBER after 100 attempts");
        }
        System.out.println("📌 FINAL APPLICATION_NUMBER = " + applicationNumber);
        return applicationNumber;
    }

    private Date parseDate(String dateStr) {
        if (dateStr == null || dateStr.trim().isEmpty()) return null;
        try {
            return new Date(new java.text.SimpleDateFormat("yyyy-MM-dd").parse(dateStr).getTime());
        } catch (Exception e) {
            return null;
        }
    }

    private Integer parseInt(String str) {
        if (str == null || str.trim().isEmpty()) return null;
        try {
            return Integer.parseInt(str.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Double parseDouble(String str) {
        if (str == null || str.trim().isEmpty()) return null;
        try {
            return Double.parseDouble(str.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private String trimSafe(String str) {
        return (str == null) ? null : str.trim();
    }

    // ========= Servlet =========

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        response.setContentType("text/html;charset=UTF-8");

        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("branchCode") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        String branchCode = trimSafe((String) session.getAttribute("branchCode"));
        String userId     = trimSafe((String) session.getAttribute("userId"));
        String productCode = trimSafe(request.getParameter("productCode"));
        String customerId  = trimSafe(request.getParameter("customerId"));

        if (productCode == null || productCode.isEmpty()) {
            response.sendRedirect("loan.jsp?status=error&message=" +
                java.net.URLEncoder.encode("Product Code required", "UTF-8"));
            return;
        }

        if (customerId == null || customerId.isEmpty()) {
            response.sendRedirect("loan.jsp?status=error&message=" +
                java.net.URLEncoder.encode("Customer ID required", "UTF-8") +
                "&productCode=" + productCode);
            return;
        }

        Connection conn = null;
        PreparedStatement psApp          = null;
        PreparedStatement psLoan         = null;
        PreparedStatement psNominee      = null;
        PreparedStatement psCoBorrower   = null;
        PreparedStatement psGuarantor    = null;
        PreparedStatement psLandBuild    = null;
        PreparedStatement psDeposit      = null;
        PreparedStatement psGold         = null;
        PreparedStatement psPlant 	     = null;
        PreparedStatement psVehicle      = null;
        PreparedStatement psInsurance    = null;
        PreparedStatement psMarketShares = null;
        PreparedStatement psStock        = null;
        PreparedStatement psSalary       = null;
        PreparedStatement psMotor        = null;
        PreparedStatement psOffice       = null;
        PreparedStatement psNonMotor     = null;
        PreparedStatement psGovSec       = null;
        String applicationNumber = null;

        try {
            conn = DBConnection.getConnection();
            conn.setAutoCommit(false);

            applicationNumber = generateApplicationNumber(conn, branchCode);

            // ================================================================
            // 1. INSERT APPLICATION  →  APPLICATION.APPLICATION
            // ================================================================
            String appSQL =
                "INSERT INTO APPLICATION.APPLICATION (" +
                "APPLICATION_NUMBER, BRANCH_CODE, PRODUCT_CODE, APPLICATIONDATE, " +
                "CUSTOMER_ID, ACCOUNTOPERATIONCAPACITY_ID, USER_ID, MINBALANCE_ID, " +
                "INTRODUCERACCOUNT_CODE, CATEGORY_CODE, NAME, INTRODUCER_NAME, " +
                "RISKCATEGORY, STATUS) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 'E')";

            psApp = conn.prepareStatement(appSQL);
            psApp.setString(1, applicationNumber);
            psApp.setString(2, branchCode);
            psApp.setString(3, productCode);
            psApp.setDate(4, parseDate(request.getParameter("dateOfApplication")));
            psApp.setString(5, customerId);

            Integer accOpCap = parseInt(request.getParameter("accountOperationCapacity"));
            if (accOpCap != null) psApp.setInt(6, accOpCap);
            else psApp.setNull(6, Types.INTEGER);

            psApp.setString(7, userId);

            Integer minBal = parseInt(request.getParameter("minBalanceID"));
            if (minBal != null) psApp.setInt(8, minBal);
            else psApp.setNull(8, Types.INTEGER);

            psApp.setString(9,  trimSafe(request.getParameter("introducerAccCode")));
            psApp.setString(10, trimSafe(request.getParameter("categoryCode")));
            psApp.setString(11, trimSafe(request.getParameter("customerName")));
            psApp.setString(12, trimSafe(request.getParameter("introducerAccName")));
            psApp.setString(13, trimSafe(request.getParameter("riskCategory")));
            psApp.executeUpdate();

            // ================================================================
            // 2. INSERT LOAN DETAILS  →  APPLICATION.APPLICATIONLOAN
            // ================================================================
            String loanSQL =
                "INSERT INTO APPLICATION.APPLICATIONLOAN (" +
                "APPLICATION_NUMBER, SANCTIONAUTHORITY_ID, MODEOFSANCTION_ID, " +
                "SOCIALSECTOR_ID, SOCIALSECTION_ID, SOCIALSUBSECTOR_ID, PURPOSE_ID, " +
                "INDUSTRY_ID, REPAYMENTFREQUENCY, IS_CONSORTIUM_LOAN, DRAWINGPOWER, " +
                "LIMITAMOUNT, SANCTIONDATE, ACCOUNTREVIEWDATE, INSTALLMENTAMOUNT, " +
                "MORATORIUMPEROIDMONTH, DOCUMENTSUBMISSIONDATE, DATEOFREGISTRATION, " +
                "REGISTERAMOUNT, RESOLUTIONNUMBER, PERIODOFLOAN, DIRECTOR_ID, " +
                "MIS_ID, CLASSIFICATION_ID, DATETIMESTAMP, CURRENTINTERESTRATE, " +
                "CURRENTPENALINTERESTRATE, CURRENTOVERDUEINTERESTRATE, " +
                "CURRENTMORATORIUMINTERESTRATE, INTERESTCALCULATIONMETHOD, " +
                "INSTALLMENTTYPE_ID, IS_DIRECTOR_RELATED, SANCTIONAMOUNT, " +
                "AREA_CODE, SUBAREA_CODE, CREATED_DATE, MODIFIED_DATE, " +
                "MEMBER_TYPE, MEMBER_NO) " +
                "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

            psLoan = conn.prepareStatement(loanSQL);
            int idx = 1;

            psLoan.setString(idx++, applicationNumber);           // 1

            Integer sanctionAuthorityId = parseInt(request.getParameter("sanctionAuthorityId"));
            Integer modeOfSanId         = parseInt(request.getParameter("modeOfSanId"));
            Integer socialSectorId      = parseInt(request.getParameter("socialSectorId"));
            Integer socialSectionId     = parseInt(request.getParameter("socialSectionId"));
            Integer socialSubSectorId   = parseInt(request.getParameter("socialSubSectorId"));
            Integer purposeId           = parseInt(request.getParameter("purposeId"));
            Integer industryId          = parseInt(request.getParameter("industryId"));
            Integer directorId          = parseInt(request.getParameter("directorId"));
            Integer misId               = parseInt(request.getParameter("lbrCode"));
            Integer classificationId    = parseInt(request.getParameter("classificationId"));

            // Debug log
            System.out.println(">> sanctionAuthorityId = " + sanctionAuthorityId);
            System.out.println(">> modeOfSanId         = " + modeOfSanId);
            System.out.println(">> socialSectorId      = " + socialSectorId);
            System.out.println(">> socialSectionId     = " + socialSectionId);
            System.out.println(">> socialSubSectorId   = " + socialSubSectorId);
            System.out.println(">> purposeId           = " + purposeId);
            System.out.println(">> industryId          = " + industryId);
            System.out.println(">> misId               = " + misId);
            System.out.println(">> classificationId    = " + classificationId);

            if (sanctionAuthorityId == null || modeOfSanId == null || socialSectorId == null ||
                socialSectionId == null || socialSubSectorId == null || purposeId == null ||
                industryId == null || misId == null || classificationId == null) {
                conn.rollback();
                response.sendRedirect("loan.jsp?status=error&message=" +
                    java.net.URLEncoder.encode("Mandatory loan master fields missing", "UTF-8") +
                    "&productCode=" + productCode);
                return;
            }

            psLoan.setInt(idx++, sanctionAuthorityId);   // 2
            psLoan.setInt(idx++, modeOfSanId);           // 3
            psLoan.setInt(idx++, socialSectorId);        // 4
            psLoan.setInt(idx++, socialSectionId);       // 5
            psLoan.setInt(idx++, socialSubSectorId);     // 6
            psLoan.setInt(idx++, purposeId);             // 7
            psLoan.setInt(idx++, industryId);            // 8

            String repaymentFreq = trimSafe(request.getParameter("repaymentFreq"));
            if (repaymentFreq != null && !repaymentFreq.isEmpty())
                psLoan.setString(idx++, repaymentFreq);
            else psLoan.setNull(idx++, Types.CHAR);      // 9

            String consortiumLoan = trimSafe(request.getParameter("consortiumLoan"));
            if (consortiumLoan != null && !consortiumLoan.isEmpty())
                psLoan.setString(idx++, consortiumLoan);
            else psLoan.setNull(idx++, Types.CHAR);      // 10

            Double drawingPower = parseDouble(request.getParameter("drawingPower"));
            if (drawingPower != null) psLoan.setDouble(idx++, drawingPower);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 11

            Double limitAmount = parseDouble(request.getParameter("limitAmount"));
            if (limitAmount != null) psLoan.setDouble(idx++, limitAmount);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 12

            psLoan.setDate(idx++, parseDate(request.getParameter("sanctionDate")));   // 13
            psLoan.setDate(idx++, parseDate(request.getParameter("reviewDate")));     // 14

            Double instAmount = parseDouble(request.getParameter("instAmount"));
            if (instAmount != null) psLoan.setDouble(idx++, instAmount);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 15

            Integer morPeriodMonth = parseInt(request.getParameter("morPeriodMonth"));
            if (morPeriodMonth != null) psLoan.setInt(idx++, morPeriodMonth);
            else psLoan.setNull(idx++, Types.INTEGER);   // 16

            psLoan.setDate(idx++, parseDate(request.getParameter("submissionDate")));   // 17
            psLoan.setDate(idx++, parseDate(request.getParameter("registrationDate"))); // 18

            Double registerAmount = parseDouble(request.getParameter("registerAmount"));
            if (registerAmount != null) psLoan.setDouble(idx++, registerAmount);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 19

            psLoan.setString(idx++, trimSafe(request.getParameter("resolutionNo")));   // 20

            Integer loanPeriod = parseInt(request.getParameter("loanPeriod"));
            if (loanPeriod != null) psLoan.setInt(idx++, loanPeriod);
            else psLoan.setNull(idx++, Types.INTEGER);   // 21

            psLoan.setInt(idx++, directorId != null ? directorId : 0);  // 22 DIRECTOR_ID

            psLoan.setInt(idx++, misId);           // 23 MIS_ID
            psLoan.setInt(idx++, classificationId); // 24 CLASSIFICATION_ID

            psLoan.setTimestamp(idx++, new Timestamp(System.currentTimeMillis())); // 25

            Double interestRate = parseDouble(request.getParameter("interestRate"));
            if (interestRate != null) psLoan.setDouble(idx++, interestRate);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 26

            Double penalIntRate = parseDouble(request.getParameter("penalIntRate"));
            if (penalIntRate != null) psLoan.setDouble(idx++, penalIntRate);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 27

            Double overdueIntRate = parseDouble(request.getParameter("overdueIntRate"));
            if (overdueIntRate != null) psLoan.setDouble(idx++, overdueIntRate);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 28

            Double morIntRate = parseDouble(request.getParameter("morIntRate"));
            if (morIntRate != null) psLoan.setDouble(idx++, morIntRate);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 29

            psLoan.setString(idx++, trimSafe(request.getParameter("intCalcMethod")));  // 30

            Integer installmentTypeId = parseInt(request.getParameter("installmentTypeId"));
            if (installmentTypeId != null) psLoan.setInt(idx++, installmentTypeId);
            else psLoan.setNull(idx++, Types.INTEGER);   // 31

            String isDirectorRelated = trimSafe(request.getParameter("isDirectorRelated"));
            if (isDirectorRelated != null && !isDirectorRelated.isEmpty())
                psLoan.setString(idx++, isDirectorRelated);
            else psLoan.setNull(idx++, Types.CHAR);      // 32

            Double sanctionAmount = parseDouble(request.getParameter("sanctionAmount"));
            if (sanctionAmount != null) psLoan.setDouble(idx++, sanctionAmount);
            else psLoan.setNull(idx++, Types.DECIMAL);   // 33

            Integer areaCode = parseInt(request.getParameter("areaCode"));
            if (areaCode != null) psLoan.setInt(idx++, areaCode);
            else psLoan.setNull(idx++, Types.INTEGER);   // 34

            Integer subAreaCode = parseInt(request.getParameter("subAreaCode"));
            if (subAreaCode != null) psLoan.setInt(idx++, subAreaCode);
            else psLoan.setNull(idx++, Types.INTEGER);   // 35

            Timestamp now = new Timestamp(System.currentTimeMillis());
            psLoan.setTimestamp(idx++, now);             // 36 CREATED_DATE
            psLoan.setTimestamp(idx++, now);             // 37 MODIFIED_DATE
            psLoan.setNull(idx++, Types.CHAR);           // 38 MEMBER_TYPE
            psLoan.setNull(idx++, Types.INTEGER);        // 39 MEMBER_NO

            

            psLoan.executeUpdate();

            // ================================================================
            // 3. INSERT NOMINEES  →  APPLICATION.APPLICATIONNOMINEE
            // ================================================================
            String[] nomineeNames      = request.getParameterValues("nomineeName[]");
            String[] nomineeSalutations= request.getParameterValues("nomineeSalutation[]");
            String[] nomineeRelations  = request.getParameterValues("nomineeRelation[]");
            String[] nomineeAddr1      = request.getParameterValues("nomineeAddress1[]");
            String[] nomineeAddr2      = request.getParameterValues("nomineeAddress2[]");
            String[] nomineeAddr3      = request.getParameterValues("nomineeAddress3[]");
            String[] nomineeCities     = request.getParameterValues("nomineeCity[]");
            String[] nomineeStates     = request.getParameterValues("nomineeState[]");
            String[] nomineeCountries  = request.getParameterValues("nomineeCountry[]");
            String[] nomineeZips       = request.getParameterValues("nomineeZip[]");

            if (nomineeNames != null && nomineeNames.length > 0) {
                String nomSQL =
                    "INSERT INTO APPLICATION.APPLICATIONNOMINEE (" +
                    "APPLICATION_NUMBER, SERIAL_NUMBER, SALUTATION_CODE, NAME, " +
                    "RELATION_ID, ADDRESS1, ADDRESS2, ADDRESS3, CITY_CODE, " +
                    "STATE_CODE, COUNTRY_CODE, ZIP) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";

                psNominee = conn.prepareStatement(nomSQL);
                int serial = 1;
                int validNom = 0;

                for (int i = 0; i < nomineeNames.length; i++) {
                    String name = trimSafe(nomineeNames[i]);
                    if (name == null || name.isEmpty()) {
                        System.out.println("⚠️ Skip nominee " + (i + 1) + " - empty name");
                        continue;
                    }
                    String sal = nomineeSalutations != null && i < nomineeSalutations.length
                                 ? trimSafe(nomineeSalutations[i]) : null;
                    if (sal == null || sal.isEmpty()) {
                        System.out.println("⚠️ Skip nominee " + (i + 1) + " - no salutation");
                        continue;
                    }

                    System.out.println("✅ Nominee " + serial + ": " + name);

                    psNominee.setString(1, applicationNumber);
                    psNominee.setInt(2, serial);
                    psNominee.setString(3, sal);
                    psNominee.setString(4, name);

                    Integer rel = nomineeRelations != null && i < nomineeRelations.length
                                  ? parseInt(nomineeRelations[i]) : null;
                    if (rel != null) psNominee.setInt(5, rel);
                    else psNominee.setNull(5, Types.INTEGER);

                    psNominee.setString(6, nomineeAddr1 != null && i < nomineeAddr1.length
                                          ? trimSafe(nomineeAddr1[i]) : null);
                    psNominee.setString(7, nomineeAddr2 != null && i < nomineeAddr2.length
                                          ? trimSafe(nomineeAddr2[i]) : null);
                    psNominee.setString(8, nomineeAddr3 != null && i < nomineeAddr3.length
                                          ? trimSafe(nomineeAddr3[i]) : null);
                    psNominee.setString(9, nomineeCities != null && i < nomineeCities.length
                                          ? trimSafe(nomineeCities[i]) : null);
                    psNominee.setString(10, nomineeStates != null && i < nomineeStates.length
                                           ? trimSafe(nomineeStates[i]) : null);
                    psNominee.setString(11, nomineeCountries != null && i < nomineeCountries.length
                                           ? trimSafe(nomineeCountries[i]) : null);

                    Integer zip = nomineeZips != null && i < nomineeZips.length
                                  ? parseInt(nomineeZips[i]) : null;
                    if (zip != null && zip != 0) psNominee.setInt(12, zip);
                    else psNominee.setNull(12, Types.INTEGER);

                    psNominee.addBatch();
                    validNom++;
                    serial++;
                }
                if (validNom > 0) {
                    psNominee.executeBatch();
                    System.out.println("Nominees inserted: " + validNom);
                }
            }

            // ================================================================
            // 4. INSERT CO-BORROWERS  →  APPLICATION.APPLICATIONJOINTHOLDER
            // ================================================================
            String[] coBorrowerNames      = request.getParameterValues("coBorrowerName[]");
            String[] coBorrowerSalutations= request.getParameterValues("coBorrowerSalutation[]");
            String[] coBorrowerAddr1      = request.getParameterValues("coBorrowerAddress1[]");
            String[] coBorrowerAddr2      = request.getParameterValues("coBorrowerAddress2[]");
            String[] coBorrowerAddr3      = request.getParameterValues("coBorrowerAddress3[]");
            String[] coBorrowerCities     = request.getParameterValues("coBorrowerCity[]");
            String[] coBorrowerStates     = request.getParameterValues("coBorrowerState[]");
            String[] coBorrowerCountries  = request.getParameterValues("coBorrowerCountry[]");
            String[] coBorrowerZips       = request.getParameterValues("coBorrowerZip[]");
            String[] coBorrowerCustIDs    = request.getParameterValues("coBorrowerCustomerID[]");

            if (coBorrowerNames != null && coBorrowerNames.length > 0) {
                String cbSQL =
                    "INSERT INTO APPLICATION.APPLICATIONJOINTHOLDER (" +
                    "APPLICATION_NUMBER, SERIAL_NUMBER, SALUTATION_CODE, NAME, " +
                    "ADDRESS1, ADDRESS2, ADDRESS3, CITY_CODE, STATE_CODE, " +
                    "COUNTRY_CODE, ZIP, CUSTOMER_ID) VALUES (?,?,?,?,?,?,?,?,?,?,?,?)";

                psCoBorrower = conn.prepareStatement(cbSQL);
                int serial = 1;
                int validCb = 0;

                for (int i = 0; i < coBorrowerNames.length; i++) {
                    String name = trimSafe(coBorrowerNames[i]);
                    if (name == null || name.isEmpty()) {
                        System.out.println("⚠️ Skip co-borrower " + (i + 1) + " - empty name");
                        continue;
                    }
                    String sal = coBorrowerSalutations != null && i < coBorrowerSalutations.length
                                 ? trimSafe(coBorrowerSalutations[i]) : null;
                    if (sal == null || sal.isEmpty()) {
                        System.out.println("⚠️ Skip co-borrower " + (i + 1) + " - no salutation");
                        continue;
                    }

                    System.out.println("✅ Co-Borrower " + serial + ": " + name);

                    psCoBorrower.setString(1, applicationNumber);
                    psCoBorrower.setInt(2, serial);
                    psCoBorrower.setString(3, sal);
                    psCoBorrower.setString(4, name);
                    psCoBorrower.setString(5, coBorrowerAddr1 != null && i < coBorrowerAddr1.length
                                             ? trimSafe(coBorrowerAddr1[i]) : null);
                    psCoBorrower.setString(6, coBorrowerAddr2 != null && i < coBorrowerAddr2.length
                                             ? trimSafe(coBorrowerAddr2[i]) : null);
                    psCoBorrower.setString(7, coBorrowerAddr3 != null && i < coBorrowerAddr3.length
                                             ? trimSafe(coBorrowerAddr3[i]) : null);
                    psCoBorrower.setString(8, coBorrowerCities != null && i < coBorrowerCities.length
                                             ? trimSafe(coBorrowerCities[i]) : null);
                    psCoBorrower.setString(9, coBorrowerStates != null && i < coBorrowerStates.length
                                             ? trimSafe(coBorrowerStates[i]) : null);
                    psCoBorrower.setString(10, coBorrowerCountries != null && i < coBorrowerCountries.length
                                              ? trimSafe(coBorrowerCountries[i]) : null);

                    Integer zip = coBorrowerZips != null && i < coBorrowerZips.length
                                  ? parseInt(coBorrowerZips[i]) : null;
                    if (zip != null && zip != 0) psCoBorrower.setInt(11, zip);
                    else psCoBorrower.setNull(11, Types.INTEGER);

                    String custId = coBorrowerCustIDs != null && i < coBorrowerCustIDs.length
                                    ? trimSafe(coBorrowerCustIDs[i]) : null;
                    if (custId != null && !custId.isEmpty()) psCoBorrower.setString(12, custId);
                    else psCoBorrower.setNull(12, Types.VARCHAR);

                    psCoBorrower.addBatch();
                    validCb++;
                    serial++;
                }
                if (validCb > 0) {
                    psCoBorrower.executeBatch();
                    System.out.println("Co-Borrowers inserted: " + validCb);
                }
            }

            // ================================================================
            // 5. INSERT GUARANTORS  →  APPLICATION.APPLICATIONGUARANTOR
            // ================================================================
            String[] guarantorNames      = request.getParameterValues("guarantorName[]");
            String[] guarantorBirthDates = request.getParameterValues("guarantorBirthDate[]");
            String[] guarantorAddr1      = request.getParameterValues("guarantorAddress1[]");
            String[] guarantorAddr2      = request.getParameterValues("guarantorAddress2[]");
            String[] guarantorAddr3      = request.getParameterValues("guarantorAddress3[]");
            String[] guarantorCities     = request.getParameterValues("guarantorCity[]");
            String[] guarantorStates     = request.getParameterValues("guarantorState[]");
            String[] guarantorCountries  = request.getParameterValues("guarantorCountry[]");
            String[] guarantorZips       = request.getParameterValues("guarantorZip[]");
            String[] guarantorPhoneNos   = request.getParameterValues("guarantorPhoneNo[]");
            String[] guarantorMobileNos  = request.getParameterValues("guarantorMobileNo[]");
            String[] guarantorCustIDs    = request.getParameterValues("guarantorCustomerID[]");
            String[] guarantorMemberNos  = request.getParameterValues("guarantorMemberNo[]");
            String[] guarantorEmployeeIds= request.getParameterValues("guarantorEmployeeId[]");

            if (guarantorNames != null && guarantorNames.length > 0) {
                String gSQL =
                    "INSERT INTO APPLICATION.APPLICATIONGUARANTOR (" +
                    "APPLICATION_NUMBER, SERIAL_NUMBER, NAME, DATEOFBIRTH, " +
                    "ADDRESS1, ADDRESS2, ADDRESS3, CITY_CODE, STATE_CODE, " +
                    "COUNTRY_CODE, ZIP, PHONENUMBER, MOBILENUMBER, CUSTOMER_ID, " +
                    "MEMBER_NO, EMPLOYEE_ID, DATETIMESTAMP, CREATED_DATE, MODIFIED_DATE" +
                    ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

                psGuarantor = conn.prepareStatement(gSQL);
                int serial = 1;
                int validG = 0;

                for (int i = 0; i < guarantorNames.length; i++) {
                    String name = trimSafe(guarantorNames[i]);
                    if (name == null || name.isEmpty()) {
                        System.out.println("⚠️ Skip guarantor " + (i + 1) + " - empty name");
                        continue;
                    }

                    Date dob         = guarantorBirthDates != null && i < guarantorBirthDates.length
                                       ? parseDate(guarantorBirthDates[i]) : null;
                    String cityCode  = guarantorCities != null && i < guarantorCities.length
                                       ? trimSafe(guarantorCities[i]) : null;
                    String stateCode = guarantorStates != null && i < guarantorStates.length
                                       ? trimSafe(guarantorStates[i]) : null;
                    String countryCode = guarantorCountries != null && i < guarantorCountries.length
                                         ? trimSafe(guarantorCountries[i]) : null;

                    if (dob == null || cityCode == null || cityCode.isEmpty()
                            || stateCode == null || stateCode.isEmpty()
                            || countryCode == null || countryCode.isEmpty()) {
                        System.out.println("⚠️ Skip guarantor " + (i + 1) + " - missing DOB/city/state/country");
                        continue;
                    }

                    System.out.println("✅ Guarantor " + serial + ": " + name);

                    int gIdx = 1;
                    psGuarantor.setString(gIdx++, applicationNumber);
                    psGuarantor.setInt(gIdx++, serial);
                    psGuarantor.setString(gIdx++, name);
                    psGuarantor.setDate(gIdx++, dob);

                    psGuarantor.setString(gIdx++, guarantorAddr1 != null && i < guarantorAddr1.length
                                                     ? trimSafe(guarantorAddr1[i]) : null);
                    psGuarantor.setString(gIdx++, guarantorAddr2 != null && i < guarantorAddr2.length
                                                     ? trimSafe(guarantorAddr2[i]) : null);
                    psGuarantor.setString(gIdx++, guarantorAddr3 != null && i < guarantorAddr3.length
                                                     ? trimSafe(guarantorAddr3[i]) : null);
                    psGuarantor.setString(gIdx++, cityCode);
                    psGuarantor.setString(gIdx++, stateCode);
                    psGuarantor.setString(gIdx++, countryCode);

                    Integer zip = guarantorZips != null && i < guarantorZips.length
                                  ? parseInt(guarantorZips[i]) : null;
                    if (zip != null && zip != 0) psGuarantor.setInt(gIdx++, zip);
                    else psGuarantor.setNull(gIdx++, Types.INTEGER);

                    psGuarantor.setString(gIdx++, guarantorPhoneNos != null && i < guarantorPhoneNos.length
                                                   ? trimSafe(guarantorPhoneNos[i]) : null);
                    psGuarantor.setString(gIdx++, guarantorMobileNos != null && i < guarantorMobileNos.length
                                                   ? trimSafe(guarantorMobileNos[i]) : null);

                    String custId = guarantorCustIDs != null && i < guarantorCustIDs.length
                                    ? trimSafe(guarantorCustIDs[i]) : null;
                    if (custId != null && !custId.isEmpty()) psGuarantor.setString(gIdx++, custId);
                    else psGuarantor.setNull(gIdx++, Types.CHAR);

                    Integer memberNo = guarantorMemberNos != null && i < guarantorMemberNos.length
                                       ? parseInt(guarantorMemberNos[i]) : null;
                    if (memberNo != null) psGuarantor.setInt(gIdx++, memberNo);
                    else psGuarantor.setNull(gIdx++, Types.INTEGER);

                    Integer empId = guarantorEmployeeIds != null && i < guarantorEmployeeIds.length
                                    ? parseInt(guarantorEmployeeIds[i]) : null;
                    if (empId != null) psGuarantor.setInt(gIdx++, empId);
                    else psGuarantor.setNull(gIdx++, Types.INTEGER);

                    Timestamp tsNow = new Timestamp(System.currentTimeMillis());
                    psGuarantor.setTimestamp(gIdx++, tsNow); // DATETIMESTAMP
                    psGuarantor.setTimestamp(gIdx++, tsNow); // CREATED_DATE
                    psGuarantor.setTimestamp(gIdx++, tsNow); // MODIFIED_DATE

                    psGuarantor.addBatch();
                    validG++;
                    serial++;
                }
                if (validG > 0) {
                    psGuarantor.executeBatch();
                    System.out.println("Guarantors inserted: " + validG);
                }
            }

            // ================================================================
            // 6. INSERT LAND & BUILDING  →  APPLICATION.APPLICATIONSECURITYLANDNBULDIN
            // ================================================================
            String[] lbSecurityTypes = request.getParameterValues("securityTypeCode[]");
            String[] lbSubmiDates    = request.getParameterValues("lbSubmiDate[]");
            String[] lbAmtValued     = request.getParameterValues("lbAmtValued[]");
            String[] lbMargins       = request.getParameterValues("lbMargin[]");
            String[] lbAreas         = request.getParameterValues("lbArea[]");
            String[] lbUnitOfAreas   = request.getParameterValues("lbUnitOfArea[]");
            String[] lbLocations     = request.getParameterValues("lbLocation[]");
            String[] lbSecurityValues= request.getParameterValues("lbSecurityValue[]");
            String[] lbRemarks       = request.getParameterValues("lbRemark[]");
            String[] lbParticulars   = request.getParameterValues("lbParticular[]");

            if (lbSecurityTypes != null && lbSecurityTypes.length > 0) {
                String lbSQL =
                    "INSERT INTO APPLICATION.APPLICATIONSECURITYLANDNBULDIN (" +
                    "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, SUBMISSIONDATE, " +
                    "VALUEDAMOUNT, MARGINEPERCENTAGE, AREA, UNITOFAREA, LOCATION, " +
                    "SECURITYVALUE, REMARK, PARTICULAR, CREATED_DATE, MODIFIED_DATE) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

                psLandBuild = conn.prepareStatement(lbSQL);
                int serialNum = 1;
                int validLb = 0;

                for (int i = 0; i < lbSecurityTypes.length; i++) {
                    String secType = trimSafe(lbSecurityTypes[i]);
                    if (secType == null || secType.isEmpty()) {
                        System.out.println("⚠️ Skip land & building " + (i + 1) + " - missing security type");
                        continue;
                    }

                    System.out.println("✅ Land & Building " + serialNum + ": " + secType);

                    int c = 1;
                    psLandBuild.setString(c++, applicationNumber);
                    psLandBuild.setInt(c++, serialNum);
                    psLandBuild.setString(c++, secType);

                    Date submiDate = lbSubmiDates != null && i < lbSubmiDates.length
                                     ? parseDate(lbSubmiDates[i]) : null;
                    if (submiDate != null) psLandBuild.setDate(c++, submiDate);
                    else psLandBuild.setNull(c++, Types.DATE);

                    Double amtValued = lbAmtValued != null && i < lbAmtValued.length
                                       ? parseDouble(lbAmtValued[i]) : null;
                    if (amtValued != null) psLandBuild.setDouble(c++, amtValued);
                    else psLandBuild.setNull(c++, Types.DECIMAL);

                    Double marginPct = lbMargins != null && i < lbMargins.length
                                       ? parseDouble(lbMargins[i]) : null;
                    if (marginPct != null) psLandBuild.setDouble(c++, marginPct);
                    else psLandBuild.setNull(c++, Types.DECIMAL);

                    Double area = lbAreas != null && i < lbAreas.length
                                  ? parseDouble(lbAreas[i]) : null;
                    if (area != null) psLandBuild.setDouble(c++, area);
                    else psLandBuild.setNull(c++, Types.DECIMAL);

                    String unitOfArea = lbUnitOfAreas != null && i < lbUnitOfAreas.length
                                        ? trimSafe(lbUnitOfAreas[i]) : null;
                    if (unitOfArea != null && !unitOfArea.isEmpty()) psLandBuild.setString(c++, unitOfArea);
                    else psLandBuild.setNull(c++, Types.CHAR);

                    String location = lbLocations != null && i < lbLocations.length
                                      ? trimSafe(lbLocations[i]) : null;
                    if (location != null && !location.isEmpty()) psLandBuild.setString(c++, location);
                    else psLandBuild.setNull(c++, Types.VARCHAR);

                    Double secValue = lbSecurityValues != null && i < lbSecurityValues.length
                                      ? parseDouble(lbSecurityValues[i]) : null;
                    if (secValue != null) psLandBuild.setDouble(c++, secValue);
                    else psLandBuild.setNull(c++, Types.DECIMAL);

                    String remark = lbRemarks != null && i < lbRemarks.length
                                    ? trimSafe(lbRemarks[i]) : null;
                    if (remark != null && !remark.isEmpty()) psLandBuild.setString(c++, remark);
                    else psLandBuild.setNull(c++, Types.VARCHAR);

                    String particular = lbParticulars != null && i < lbParticulars.length
                                        ? trimSafe(lbParticulars[i]) : null;
                    if (particular != null && !particular.isEmpty()) psLandBuild.setString(c++, particular);
                    else psLandBuild.setNull(c++, Types.VARCHAR);

                    Timestamp lbNow = new Timestamp(System.currentTimeMillis());
                    psLandBuild.setTimestamp(c++, lbNow); // CREATED_DATE
                    psLandBuild.setTimestamp(c++, lbNow); // MODIFIED_DATE

                    psLandBuild.addBatch();
                    validLb++;
                    serialNum++;
                }
                if (validLb > 0) {
                    psLandBuild.executeBatch();
                    System.out.println("Land & Building records inserted: " + validLb);
                }
            }

            // ================================================================
            // 7. INSERT DEPOSIT DETAILS  →  APPLICATION.APPLICATIONSECURITYDEPOSIT
            // ================================================================
            String[] securityTypeCodes    = request.getParameterValues("securityTypeCode[]");
            String[] depositSubmiDates    = request.getParameterValues("submissionDate[]");
            String[] marginPercents       = request.getParameterValues("marginPercent[]");
            String[] depositAccCodes      = request.getParameterValues("depositAccCode[]");
            String[] maturityDates        = request.getParameterValues("maturityDate[]");
            String[] securityValues       = request.getParameterValues("securityValue[]");
            String[] tdValues             = request.getParameterValues("tdValue[]");
            String[] particulars          = request.getParameterValues("particular[]");

            // Only run deposit logic when the deposit fieldset fields are present
            // (distinguished from L&B by presence of depositAccCode[])
            if (depositAccCodes != null && depositAccCodes.length > 0) {
                String depSQL =
                    "INSERT INTO APPLICATION.APPLICATIONSECURITYDEPOSIT (" +
                    "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, SUBMISSIONDATE, " +
                    "DEPOSITACCOUNT_CODE, MARGINPERCENTAGE, MATURITYDATE, SECURITYVALUE, " +
                    "PARTICULAR, DATETIMESTAMP, TD_VALUE) VALUES (?,?,?,?,?,?,?,?,?,?,?)";

                psDeposit = conn.prepareStatement(depSQL);
                int serialNum = 1;
                int validDep = 0;

                for (int i = 0; i < depositAccCodes.length; i++) {
                    String depAccCode = trimSafe(depositAccCodes[i]);
                    String secTypeCode = securityTypeCodes != null && i < securityTypeCodes.length
                                         ? trimSafe(securityTypeCodes[i]) : null;

                    if (depAccCode == null || depAccCode.isEmpty()
                            || secTypeCode == null || secTypeCode.isEmpty()) {
                        System.out.println("⚠️ Skip deposit " + (i + 1) + " - missing required fields");
                        continue;
                    }

                    System.out.println("✅ Deposit " + serialNum + ": " + secTypeCode + " A/c: " + depAccCode);

                    int c = 1;
                    psDeposit.setString(c++, applicationNumber);
                    psDeposit.setInt(c++, serialNum);
                    psDeposit.setString(c++, secTypeCode);

                    Date depSubDate = depositSubmiDates != null && i < depositSubmiDates.length
                                      ? parseDate(depositSubmiDates[i]) : null;
                    if (depSubDate != null) psDeposit.setDate(c++, depSubDate);
                    else psDeposit.setNull(c++, Types.DATE);

                    psDeposit.setString(c++, depAccCode);

                    Double marginPct = marginPercents != null && i < marginPercents.length
                                       ? parseDouble(marginPercents[i]) : null;
                    if (marginPct != null) psDeposit.setDouble(c++, marginPct);
                    else psDeposit.setNull(c++, Types.DECIMAL);

                    Date matDate = maturityDates != null && i < maturityDates.length
                                   ? parseDate(maturityDates[i]) : null;
                    if (matDate != null) psDeposit.setDate(c++, matDate);
                    else psDeposit.setNull(c++, Types.DATE);

                    Double secValue = securityValues != null && i < securityValues.length
                                      ? parseDouble(securityValues[i]) : null;
                    if (secValue != null) psDeposit.setDouble(c++, secValue);
                    else psDeposit.setNull(c++, Types.DECIMAL);

                    String particular = particulars != null && i < particulars.length
                                        ? trimSafe(particulars[i]) : null;
                    if (particular != null && !particular.isEmpty()) psDeposit.setString(c++, particular);
                    else psDeposit.setNull(c++, Types.VARCHAR);

                    psDeposit.setTimestamp(c++, new Timestamp(System.currentTimeMillis()));

                    Double tdVal = tdValues != null && i < tdValues.length
                                   ? parseDouble(tdValues[i]) : null;
                    if (tdVal != null) psDeposit.setDouble(c++, tdVal);
                    else psDeposit.setNull(c++, Types.DECIMAL);

                    psDeposit.addBatch();
                    validDep++;
                    serialNum++;
                }
                if (validDep > 0) {
                    psDeposit.executeBatch();
                    System.out.println("Deposit records inserted: " + validDep);
                }
            }

            // ================================================================
            // 8. INSERT GOLD / SILVER  →  APPLICATION.APPLICATIONSECURITYGOLDSILVER
            // ================================================================
            String[] gsSecurityTypes = request.getParameterValues("gsSecurityType[]");
            String[] gsSubmissionDates = request.getParameterValues("gsSubmissionDate[]");
            String[] gsGoldBagNos    = request.getParameterValues("gsGoldBagNo[]");
            String[] gsTotalWeights  = request.getParameterValues("gsTotalWeight[]");
            String[] gsMargins       = request.getParameterValues("gsMargin[]");
            String[] gsRatePerGrams  = request.getParameterValues("gsRatePerGram[]");
            String[] gsTotalValues   = request.getParameterValues("gsTotalValue[]");
            String[] gsSecurityValues= request.getParameterValues("gsSecurityValue[]");
            String[] gsParticulars   = request.getParameterValues("gsParticular[]");
            String[] gsNotes         = request.getParameterValues("gsNote[]");

            if (gsSecurityTypes != null && gsSecurityTypes.length > 0) {
                String goldSQL =
                    "INSERT INTO APPLICATION.APPLICATIONSECURITYGOLDSILVER (" +
                    "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, WEIGHTTOTALGMS, " +
                    "RATEPER10GMS, TOTALVALUE, MARGINPERCENTAGE, SECURITYVALUE, PARTICULAR, " +
                    "NOTE, SUBMISSIONDATE, GOLDBAGNO, " +
                    "DATETIMESTAMP, " +
                    "CREATED_DATE, MODIFIED_DATE) " +
                    "VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

                psGold = conn.prepareStatement(goldSQL);
                int serial = 1;
                int validGs = 0;

                for (int i = 0; i < gsSecurityTypes.length; i++) {
                    String secType = trimSafe(gsSecurityTypes[i]);
                    if (secType == null || secType.isEmpty()) {
                        System.out.println("⚠️ Skip gold/silver " + (i + 1) + " - empty security type");
                        continue;
                    }

                    System.out.println("✅ Gold/Silver " + serial + ": " + secType);

                    int c = 1;
                    Timestamp gsNow = new Timestamp(System.currentTimeMillis());

                    psGold.setString(c++, applicationNumber);   // 1 APPLICATION_NUMBER
                    psGold.setInt(c++, serial);                 // 2 SERIAL_NUMBER
                    psGold.setString(c++, secType);             // 3 SECURITYTYPE_CODE

                    Double totalWeight = gsTotalWeights != null && i < gsTotalWeights.length
                                         ? parseDouble(gsTotalWeights[i]) : null;
                    if (totalWeight != null) psGold.setDouble(c++, totalWeight);
                    else psGold.setNull(c++, Types.DECIMAL);    // 4 WEIGHTTOTALGMS

                    Double ratePerGram = gsRatePerGrams != null && i < gsRatePerGrams.length
                                         ? parseDouble(gsRatePerGrams[i]) : null;
                    if (ratePerGram != null) psGold.setDouble(c++, ratePerGram);
                    else psGold.setNull(c++, Types.DECIMAL);    // 5 RATEPER10GMS

                    Double totalValue = gsTotalValues != null && i < gsTotalValues.length
                                        ? parseDouble(gsTotalValues[i]) : null;
                    if (totalValue != null) psGold.setDouble(c++, totalValue);
                    else psGold.setNull(c++, Types.DECIMAL);    // 6 TOTALVALUE

                    Double margin = gsMargins != null && i < gsMargins.length
                                    ? parseDouble(gsMargins[i]) : null;
                    if (margin != null) psGold.setDouble(c++, margin);
                    else psGold.setNull(c++, Types.DECIMAL);    // 7 MARGINPERCENTAGE

                    Double secValue = gsSecurityValues != null && i < gsSecurityValues.length
                                      ? parseDouble(gsSecurityValues[i]) : null;
                    if (secValue != null) psGold.setDouble(c++, secValue);
                    else psGold.setNull(c++, Types.DECIMAL);    // 8 SECURITYVALUE

                    String particular = gsParticulars != null && i < gsParticulars.length
                                        ? trimSafe(gsParticulars[i]) : null;
                    if (particular != null && !particular.isEmpty()) psGold.setString(c++, particular);
                    else psGold.setNull(c++, Types.VARCHAR);    // 9 PARTICULAR

                    String note = gsNotes != null && i < gsNotes.length
                                  ? trimSafe(gsNotes[i]) : null;
                    if (note != null && !note.isEmpty()) psGold.setString(c++, note);
                    else psGold.setNull(c++, Types.VARCHAR);    // 10 NOTE

                    Date subDate = gsSubmissionDates != null && i < gsSubmissionDates.length
                                   ? parseDate(gsSubmissionDates[i]) : null;
                    if (subDate != null) psGold.setDate(c++, subDate);
                    else psGold.setNull(c++, Types.DATE);       // 11 SUBMISSIONDATE

                    String goldBagNo = gsGoldBagNos != null && i < gsGoldBagNos.length
                                       ? trimSafe(gsGoldBagNos[i]) : null;
                    if (goldBagNo != null && !goldBagNo.isEmpty() && !goldBagNo.equals("0"))
                        psGold.setString(c++, goldBagNo);
                    else psGold.setNull(c++, Types.VARCHAR);    // 12 GOLDBAGNO

                    psGold.setTimestamp(c++, gsNow);            // 13 DATETIMESTAMP
                    psGold.setTimestamp(c++, gsNow);            // 14 CREATED_DATE
                    psGold.setNull(c++, Types.TIMESTAMP);       // 15 MODIFIED_DATE

                    psGold.addBatch();
                    validGs++;
                    serial++;
                }
                if (validGs > 0) {
                    psGold.executeBatch();
                    System.out.println("Gold/Silver records inserted: " + validGs);
                }
            }
            
         // ================================================================
         // 9. INSERT PLANT & MACHINERY  →  APPLICATION.APPLICATIONSECURITYPLAN
         // ================================================================
         String[] plantSecurityTypes   = request.getParameterValues("plantSecurityType[]");
         String[] plantIsNewEquips     = request.getParameterValues("plantIsNewEquip[]");
         String[] plantSubmissionDates = request.getParameterValues("plantSubmissionDate[]");
         String[] plantMachineTypes    = request.getParameterValues("plantMachineType[]");
         String[] plantMachineNames    = request.getParameterValues("plantMachineName[]");
         String[] plantDistinctiveNos  = request.getParameterValues("plantDistinctiveNo[]");
         String[] plantSpecifications  = request.getParameterValues("plantSpecification[]");
         String[] plantAquisitionDates = request.getParameterValues("plantAquisitionDate[]");
         String[] plantSupplierNames   = request.getParameterValues("plantSupplierName[]");
         String[] plantPurchasePrices  = request.getParameterValues("plantPurchasePrice[]");
         String[] plantMargins         = request.getParameterValues("plantMargin[]");
         String[] plantSecurityValues  = request.getParameterValues("plantSecurityValue[]");
         String[] plantParticulars     = request.getParameterValues("plantParticular[]");

         if (plantSecurityTypes != null && plantSecurityTypes.length > 0) {
             String plantSQL =
                 "INSERT INTO APPLICATION.APPLICATIONSECURITYPLAN (" +
                 "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, IS_NEW_EQUIPMENT, " +
                 "SUBMISSIONDATE, MACHINETYPE, MACHINENAME, DISTINCTIVENUMBER, " +
                 "SPECIFICATION, AQUISITIONDATE, SUPPLIERNAME, PURCHASEPRICE, " +
                 "MARGINPERCENTAGE, RELEASEDDATE, SECURITYVALUE, PARTICULAR, " +
                 "DATETIMESTAMP, CREATED_DATE, MODIFIED_DATE" +
                 ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

             psPlant = conn.prepareStatement(plantSQL);
             int serial = 1;
             int validPlant = 0;

             for (int i = 0; i < plantSecurityTypes.length; i++) {
                 String secType = trimSafe(plantSecurityTypes[i]);
                 if (secType == null || secType.isEmpty()) {
                     System.out.println("⚠️ Skip plant & machinery " + (i + 1) + " - empty security type");
                     continue;
                 }

                 System.out.println("✅ Plant & Machinery " + serial + ": " + secType);

                 int c = 1;
                 Timestamp plantNow = new Timestamp(System.currentTimeMillis());

                 psPlant.setString(c++, applicationNumber);                          // 1 APPLICATION_NUMBER
                 psPlant.setInt(c++, serial);                                        // 2 SERIAL_NUMBER
                 psPlant.setString(c++, secType);                                    // 3 SECURITYTYPE_CODE

                 String isNewEquip = plantIsNewEquips != null && i < plantIsNewEquips.length
                                     ? trimSafe(plantIsNewEquips[i]) : "N";
                 psPlant.setString(c++, (isNewEquip != null && !isNewEquip.isEmpty()) ? isNewEquip : "N"); // 4 IS_NEW_EQUIPMENT

                 Date plantSubDate = plantSubmissionDates != null && i < plantSubmissionDates.length
                                     ? parseDate(plantSubmissionDates[i]) : null;
                 if (plantSubDate != null) psPlant.setDate(c++, plantSubDate);
                 else psPlant.setNull(c++, Types.DATE);                              // 5 SUBMISSIONDATE

                 psPlant.setString(c++, plantMachineTypes != null && i < plantMachineTypes.length
                                        ? trimSafe(plantMachineTypes[i]) : null);   // 6 MACHINETYPE

                 psPlant.setString(c++, plantMachineNames != null && i < plantMachineNames.length
                                        ? trimSafe(plantMachineNames[i]) : null);   // 7 MACHINENAME

                 psPlant.setString(c++, plantDistinctiveNos != null && i < plantDistinctiveNos.length
                                        ? trimSafe(plantDistinctiveNos[i]) : null); // 8 DISTINCTIVENUMBER

                 psPlant.setString(c++, plantSpecifications != null && i < plantSpecifications.length
                                        ? trimSafe(plantSpecifications[i]) : null); // 9 SPECIFICATION

                 Date plantAcqDate = plantAquisitionDates != null && i < plantAquisitionDates.length
                                     ? parseDate(plantAquisitionDates[i]) : null;
                 if (plantAcqDate != null) psPlant.setDate(c++, plantAcqDate);
                 else psPlant.setNull(c++, Types.DATE);                              // 10 AQUISITIONDATE

                 psPlant.setString(c++, plantSupplierNames != null && i < plantSupplierNames.length
                                        ? trimSafe(plantSupplierNames[i]) : null);  // 11 SUPPLIERNAME

                 Double plantPrice = plantPurchasePrices != null && i < plantPurchasePrices.length
                                     ? parseDouble(plantPurchasePrices[i]) : null;
                 if (plantPrice != null) psPlant.setDouble(c++, plantPrice);
                 else psPlant.setNull(c++, Types.DECIMAL);                          // 12 PURCHASEPRICE

                 Double plantMargin = plantMargins != null && i < plantMargins.length
                                      ? parseDouble(plantMargins[i]) : null;
                 if (plantMargin != null) psPlant.setDouble(c++, plantMargin);
                 else psPlant.setNull(c++, Types.DECIMAL);                          // 13 MARGINPERCENTAGE

                 // RELEASEDDATE — not in the form, store null
                 psPlant.setNull(c++, Types.DATE);                                  // 14 RELEASEDDATE

                 Double plantSecVal = plantSecurityValues != null && i < plantSecurityValues.length
                                      ? parseDouble(plantSecurityValues[i]) : null;
                 if (plantSecVal != null) psPlant.setDouble(c++, plantSecVal);
                 else psPlant.setNull(c++, Types.DECIMAL);                          // 15 SECURITYVALUE

                 String plantParticular = plantParticulars != null && i < plantParticulars.length
                                          ? trimSafe(plantParticulars[i]) : null;
                 if (plantParticular != null && !plantParticular.isEmpty()) psPlant.setString(c++, plantParticular);
                 else psPlant.setNull(c++, Types.VARCHAR);                          // 16 PARTICULAR

                 psPlant.setTimestamp(c++, plantNow);                               // 17 DATETIMESTAMP
                 psPlant.setTimestamp(c++, plantNow);                               // 18 CREATED_DATE
                 psPlant.setNull(c++, Types.TIMESTAMP);                             // 19 MODIFIED_DATE

                 psPlant.addBatch();
                 validPlant++;
                 serial++;
             }
             if (validPlant > 0) {
                 psPlant.executeBatch();
                 System.out.println("Plant & Machinery records inserted: " + validPlant);
             }
         }

         // ================================================================
         // 10. INSERT VEHICLE  →  APPLICATION.APPLICATIONSECURITYVEHICLE
         // ================================================================
         String[] vehicleSecurityTypes    = request.getParameterValues("vehicleSecurityType[]");
         String[] vehicleSubmissionDates  = request.getParameterValues("vehicleSubmissionDate[]");
         String[] vehicleIsNewVehicles    = request.getParameterValues("vehicleIsNewVehicle[]");
         String[] vehicleIsVehicleInsps   = request.getParameterValues("vehicleIsVehicleInsp[]");
         String[] vehicleMakeModels       = request.getParameterValues("vehicleMakeModel[]");
         String[] vehicleRegistrationNos  = request.getParameterValues("vehicleRegistrationNo[]");
         String[] vehicleChasisNos        = request.getParameterValues("vehicleChasisNo[]");
         String[] vehicleAcquisitionDates = request.getParameterValues("vehicleAcquisitionDate[]");
         String[] vehicleSupplierNames    = request.getParameterValues("vehicleSupplierName[]");
         String[] vehicleRegistrationDates= request.getParameterValues("vehicleRegistrationDate[]");
         String[] vehiclePurchasePrices   = request.getParameterValues("vehiclePurchasePrice[]");
         String[] vehicleMargins          = request.getParameterValues("vehicleMargin[]");
         String[] vehicleRTOLocations     = request.getParameterValues("vehicleRTOLocation[]");

         if (vehicleSecurityTypes != null && vehicleSecurityTypes.length > 0) {
             String vehicleSQL =
                 "INSERT INTO APPLICATION.APPLICATIONSECURITYVEHICLE (" +
                 "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, SUBMISSIONDATE, " +
                 "IS_NEW_VEHICLE, IS_VEHICLE_INSPECTED, VEHICLEMAKEMODEL, VEHICLENO, " +
                 "CHASISNO, ACQUISITIONDATE, SUPPLIERNAME, RTOREGISTRATIONDATE, " +
                 "PURCHASEPRICE, MARGINEPERCENTAGE, DATETIMESTAMP, CREATED_DATE, MODIFIED_DATE" +
                 ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

             psVehicle = conn.prepareStatement(vehicleSQL);
             int serial = 1;
             int validVehicle = 0;

             for (int i = 0; i < vehicleSecurityTypes.length; i++) {
                 String secType = trimSafe(vehicleSecurityTypes[i]);
                 if (secType == null || secType.isEmpty()) {
                     System.out.println("⚠️ Skip vehicle " + (i + 1) + " - empty security type");
                     continue;
                 }

                 System.out.println("✅ Vehicle " + serial + ": " + secType);

                 int c = 1;
                 Timestamp vehicleNow = new Timestamp(System.currentTimeMillis());

                 psVehicle.setString(c++, applicationNumber);                               // 1 APPLICATION_NUMBER
                 psVehicle.setInt(c++, serial);                                             // 2 SERIAL_NUMBER
                 psVehicle.setString(c++, secType);                                         // 3 SECURITYTYPE_CODE

                 Date vSubDate = vehicleSubmissionDates != null && i < vehicleSubmissionDates.length
                                 ? parseDate(vehicleSubmissionDates[i]) : null;
                 if (vSubDate != null) psVehicle.setDate(c++, vSubDate);
                 else psVehicle.setNull(c++, Types.DATE);                                   // 4 SUBMISSIONDATE

                 String isNewVehicle = vehicleIsNewVehicles != null && i < vehicleIsNewVehicles.length
                                       ? trimSafe(vehicleIsNewVehicles[i]) : "Y";
                 psVehicle.setString(c++, (isNewVehicle != null && !isNewVehicle.isEmpty()) ? isNewVehicle : "Y"); // 5 IS_NEW_VEHICLE

                 String isVehicleInsp = vehicleIsVehicleInsps != null && i < vehicleIsVehicleInsps.length
                                        ? trimSafe(vehicleIsVehicleInsps[i]) : "Y";
                 psVehicle.setString(c++, (isVehicleInsp != null && !isVehicleInsp.isEmpty()) ? isVehicleInsp : "Y"); // 6 IS_VEHICLE_INSPECTED

                 psVehicle.setString(c++, vehicleMakeModels != null && i < vehicleMakeModels.length
                                          ? trimSafe(vehicleMakeModels[i]) : null);         // 7 VEHICLEMAKEMODEL

                 // VEHICLENO maps to vehicleRegistrationNo (vehicle number plate)
                 psVehicle.setString(c++, vehicleRegistrationNos != null && i < vehicleRegistrationNos.length
                                          ? trimSafe(vehicleRegistrationNos[i]) : null);    // 8 VEHICLENO

                 psVehicle.setString(c++, vehicleChasisNos != null && i < vehicleChasisNos.length
                                          ? trimSafe(vehicleChasisNos[i]) : null);          // 9 CHASISNO

                 Date vAcqDate = vehicleAcquisitionDates != null && i < vehicleAcquisitionDates.length
                                 ? parseDate(vehicleAcquisitionDates[i]) : null;
                 if (vAcqDate != null) psVehicle.setDate(c++, vAcqDate);
                 else psVehicle.setNull(c++, Types.DATE);                                   // 10 ACQUISITIONDATE

                 psVehicle.setString(c++, vehicleSupplierNames != null && i < vehicleSupplierNames.length
                                          ? trimSafe(vehicleSupplierNames[i]) : null);      // 11 SUPPLIERNAME

                 // RTOREGISTRATIONDATE maps to vehicleRegistrationDate
                 Date vRegDate = vehicleRegistrationDates != null && i < vehicleRegistrationDates.length
                                 ? parseDate(vehicleRegistrationDates[i]) : null;
                 if (vRegDate != null) psVehicle.setDate(c++, vRegDate);
                 else psVehicle.setNull(c++, Types.DATE);                                   // 12 RTOREGISTRATIONDATE

                 Double vPrice = vehiclePurchasePrices != null && i < vehiclePurchasePrices.length
                                 ? parseDouble(vehiclePurchasePrices[i]) : null;
                 if (vPrice != null) psVehicle.setDouble(c++, vPrice);
                 else psVehicle.setNull(c++, Types.DECIMAL);                                // 13 PURCHASEPRICE

                 Double vMargin = vehicleMargins != null && i < vehicleMargins.length
                                  ? parseDouble(vehicleMargins[i]) : null;
                 if (vMargin != null) psVehicle.setDouble(c++, vMargin);
                 else psVehicle.setNull(c++, Types.DECIMAL);                                // 14 MARGINEPERCENTAGE

                 psVehicle.setTimestamp(c++, vehicleNow);                                   // 15 DATETIMESTAMP
                 psVehicle.setTimestamp(c++, vehicleNow);                                   // 16 CREATED_DATE
                 psVehicle.setTimestamp(c++, vehicleNow);                                   // 17 MODIFIED_DATE

                 psVehicle.addBatch();
                 validVehicle++;
                 serial++;
             }
             if (validVehicle > 0) {
                 psVehicle.executeBatch();
                 System.out.println("Vehicle records inserted: " + validVehicle);
             }
         }

         // ================================================================
         // 11. INSERT INSURANCE (LIC)  →  APPLICATION.APPLICATIONSECURITYINSURANCE
         // ================================================================
         String[] insSecurityTypes  = request.getParameterValues("insSecurityType[]");
         String[] insPolicyNos      = request.getParameterValues("insPolicyNo[]");
         String[] insPolicyAmounts  = request.getParameterValues("insPolicyAmount[]");
         String[] insNames          = request.getParameterValues("insName[]");
         String[] insPremiumPeriods = request.getParameterValues("insPremiumPeriod[]");
         String[] insSecurityValues = request.getParameterValues("insSecurityValue[]");
         String[] insParticulars    = request.getParameterValues("insParticular[]");
         String[] insPremiumAmounts = request.getParameterValues("insPremiumAmount[]");
         String[] insAssuredAmounts = request.getParameterValues("insAssuredAmount[]");

         if (insSecurityTypes != null && insSecurityTypes.length > 0) {
             String insSQL =
                 "INSERT INTO APPLICATION.APPLICATIONSECURITYINSURANCE (" +
                 "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, POLICYNUMBER, " +
                 "POLICYAMOUNT, INSURANCENAME, PREMIUMPERIOD, SECURITYVALUE, " +
                 "PARTICULAR, DATETIMESTAMP, PREMIUMAMOUNT, ASSUREDAMOUNT, " +
                 "CREATED_DATE, MODIFIED_DATE" +
                 ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

             psInsurance = conn.prepareStatement(insSQL);
             int serial = 1;
             int validIns = 0;

             for (int i = 0; i < insSecurityTypes.length; i++) {
                 String secType = trimSafe(insSecurityTypes[i]);
                 if (secType == null || secType.isEmpty()) {
                     System.out.println("⚠️ Skip insurance " + (i + 1) + " - empty security type");
                     continue;
                 }

                 System.out.println("✅ Insurance " + serial + ": " + secType);

                 int c = 1;
                 Timestamp insNow = new Timestamp(System.currentTimeMillis());

                 psInsurance.setString(c++, applicationNumber);                             // 1 APPLICATION_NUMBER
                 psInsurance.setInt(c++, serial);                                           // 2 SERIAL_NUMBER
                 psInsurance.setString(c++, secType);                                       // 3 SECURITYTYPE_CODE

                 psInsurance.setString(c++, insPolicyNos != null && i < insPolicyNos.length
                                            ? trimSafe(insPolicyNos[i]) : null);            // 4 POLICYNUMBER

                 Double policyAmt = insPolicyAmounts != null && i < insPolicyAmounts.length
                                    ? parseDouble(insPolicyAmounts[i]) : null;
                 if (policyAmt != null) psInsurance.setDouble(c++, policyAmt);
                 else psInsurance.setNull(c++, Types.DECIMAL);                              // 5 POLICYAMOUNT

                 psInsurance.setString(c++, insNames != null && i < insNames.length
                                            ? trimSafe(insNames[i]) : null);                // 6 INSURANCENAME

                 // PREMIUMPERIOD is CHAR(1 BYTE) — map Monthly→M, Quarterly→Q, etc.
                 String premPeriodFull = insPremiumPeriods != null && i < insPremiumPeriods.length
                                         ? trimSafe(insPremiumPeriods[i]) : null;
                 String premPeriodCode = null;
                 if (premPeriodFull != null) {
                     switch (premPeriodFull) {
                         case "Monthly":     premPeriodCode = "M"; break;
                         case "Quarterly":   premPeriodCode = "Q"; break;
                         case "Half-Yearly": premPeriodCode = "H"; break;
                         case "Yearly":      premPeriodCode = "Y"; break;
                         default:            premPeriodCode = premPeriodFull.length() > 0
                                                              ? String.valueOf(premPeriodFull.charAt(0)) : null;
                     }
                 }
                 if (premPeriodCode != null) psInsurance.setString(c++, premPeriodCode);
                 else psInsurance.setNull(c++, Types.CHAR);                                 // 7 PREMIUMPERIOD

                 Double secVal = insSecurityValues != null && i < insSecurityValues.length
                                 ? parseDouble(insSecurityValues[i]) : null;
                 if (secVal != null) psInsurance.setDouble(c++, secVal);
                 else psInsurance.setNull(c++, Types.DECIMAL);                              // 8 SECURITYVALUE

                 String particular = insParticulars != null && i < insParticulars.length
                                     ? trimSafe(insParticulars[i]) : null;
                 if (particular != null && !particular.isEmpty()) psInsurance.setString(c++, particular);
                 else psInsurance.setNull(c++, Types.VARCHAR);                              // 9 PARTICULAR

                 psInsurance.setTimestamp(c++, insNow);                                     // 10 DATETIMESTAMP

                 Double premAmt = insPremiumAmounts != null && i < insPremiumAmounts.length
                                  ? parseDouble(insPremiumAmounts[i]) : null;
                 if (premAmt != null) psInsurance.setDouble(c++, premAmt);
                 else psInsurance.setNull(c++, Types.DECIMAL);                              // 11 PREMIUMAMOUNT

                 Double assuredAmt = insAssuredAmounts != null && i < insAssuredAmounts.length
                                     ? parseDouble(insAssuredAmounts[i]) : null;
                 if (assuredAmt != null) psInsurance.setDouble(c++, assuredAmt);
                 else psInsurance.setNull(c++, Types.DECIMAL);                              // 12 ASSUREDAMOUNT

                 psInsurance.setTimestamp(c++, insNow);                                     // 13 CREATED_DATE
                 psInsurance.setNull(c++, Types.VARCHAR);                                   // 14 MODIFIED_DATE (VARCHAR2 in schema)

                 psInsurance.addBatch();
                 validIns++;
                 serial++;
             }
             if (validIns > 0) {
                 psInsurance.executeBatch();
                 System.out.println("Insurance records inserted: " + validIns);
             }
         }
         
      // ================================================================
      // 12. INSERT MARKET SHARES  →  APPLICATION.APPLICATIONSECURITYSHARE
      // ================================================================
      String[] msSecurityTypes   = request.getParameterValues("marketSharesSecurityType[]");
      String[] msCompanyNames    = request.getParameterValues("marketSharesCompanyName[]");
      String[] msMargins         = request.getParameterValues("marketSharesMargin[]");
      String[] msSubmissionDates = request.getParameterValues("marketSharesSubmissionDate[]");
      String[] msIssueDates      = request.getParameterValues("marketSharesIssueDate[]");
      String[] msMarketValues    = request.getParameterValues("marketSharesMarketValue[]");
      String[] msNoOfShares      = request.getParameterValues("marketSharesNoOfShares[]");
      String[] msSecurityValues  = request.getParameterValues("marketSharesSecurityValue[]");
      String[] msParticulars     = request.getParameterValues("marketSharesParticular[]");

      if (msSecurityTypes != null && msSecurityTypes.length > 0) {
          String msSQL =
              "INSERT INTO APPLICATION.APPLICATIONSECURITYSHARE (" +
              "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, COMPANYNAME, " +
              "MARGINEPERCENTAGE, SUBMISSIONDATE, ISSUEDATE, MARKETVALUE, " +
              "NOOFSHARES, SECURITYVALUE, PARTICULAR, " +
              "DATETIMESTAMP, CREATED_DATE, MODIFIED_DATE" +
              ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

          psMarketShares = conn.prepareStatement(msSQL);
          int serial = 1;
          int validMs = 0;

          for (int i = 0; i < msSecurityTypes.length; i++) {
              String secType = trimSafe(msSecurityTypes[i]);
              if (secType == null || secType.isEmpty()) {
                  System.out.println("⚠️ Skip market shares " + (i + 1) + " - empty security type");
                  continue;
              }

              System.out.println("✅ Market Shares " + serial + ": " + secType);

              int c = 1;
              Timestamp msNow = new Timestamp(System.currentTimeMillis());

              psMarketShares.setString(c++, applicationNumber);                                    // 1 APPLICATION_NUMBER
              psMarketShares.setInt(c++, serial);                                                  // 2 SERIAL_NUMBER
              psMarketShares.setString(c++, secType);                                              // 3 SECURITYTYPE_CODE

              psMarketShares.setString(c++, msCompanyNames != null && i < msCompanyNames.length
                                            ? trimSafe(msCompanyNames[i]) : null);                 // 4 COMPANYNAME

              Double msMargin = msMargins != null && i < msMargins.length
                                ? parseDouble(msMargins[i]) : null;
              if (msMargin != null) psMarketShares.setDouble(c++, msMargin);
              else psMarketShares.setNull(c++, Types.DECIMAL);                                     // 5 MARGINEPERCENTAGE

              Date msSubDate = msSubmissionDates != null && i < msSubmissionDates.length
                               ? parseDate(msSubmissionDates[i]) : null;
              if (msSubDate != null) psMarketShares.setDate(c++, msSubDate);
              else psMarketShares.setNull(c++, Types.DATE);                                        // 6 SUBMISSIONDATE

              Date msIssueDate = msIssueDates != null && i < msIssueDates.length
                                 ? parseDate(msIssueDates[i]) : null;
              if (msIssueDate != null) psMarketShares.setDate(c++, msIssueDate);
              else psMarketShares.setNull(c++, Types.DATE);                                        // 7 ISSUEDATE

              Double msMarketVal = msMarketValues != null && i < msMarketValues.length
                                   ? parseDouble(msMarketValues[i]) : null;
              if (msMarketVal != null) psMarketShares.setDouble(c++, msMarketVal);
              else psMarketShares.setNull(c++, Types.DECIMAL);                                     // 8 MARKETVALUE

              Integer msShares = msNoOfShares != null && i < msNoOfShares.length
                                 ? parseInt(msNoOfShares[i]) : null;
              if (msShares != null) psMarketShares.setInt(c++, msShares);
              else psMarketShares.setNull(c++, Types.INTEGER);                                     // 9 NOOFSHARES

              Double msSecVal = msSecurityValues != null && i < msSecurityValues.length
                                ? parseDouble(msSecurityValues[i]) : null;
              if (msSecVal != null) psMarketShares.setDouble(c++, msSecVal);
              else psMarketShares.setNull(c++, Types.DECIMAL);                                     // 10 SECURITYVALUE

              String msPart = msParticulars != null && i < msParticulars.length
                              ? trimSafe(msParticulars[i]) : null;
              if (msPart != null && !msPart.isEmpty()) psMarketShares.setString(c++, msPart);
              else psMarketShares.setNull(c++, Types.VARCHAR);                                     // 11 PARTICULAR

              psMarketShares.setTimestamp(c++, msNow);                                             // 12 DATETIMESTAMP
              psMarketShares.setTimestamp(c++, msNow);                                             // 13 CREATED_DATE
              psMarketShares.setNull(c++, Types.TIMESTAMP);                                        // 14 MODIFIED_DATE

              psMarketShares.addBatch();
              validMs++;
              serial++;
          }
          if (validMs > 0) {
              psMarketShares.executeBatch();
              System.out.println("Market Shares records inserted: " + validMs);
          }
      }

      // ================================================================
      // 13. INSERT STOCK STATEMENT  →  APPLICATION.APPLICATIONSECURITYSTOCKSTATEM
      // ================================================================
      // DB stores actual rupee values (RAWMATERIALSTOCKVALUE, WIPVALUE, FINISHGOODSTOCKVALUE),
      // not margin percentages. The form captures margin % fields which are used to
      // calculate security value client-side; store the margin % values in those columns
      // as the closest available mapping until dedicated value fields are added to the form.
      String[] stSecurityTypes    = request.getParameterValues("stockSecurityType[]");
      String[] stSubmissionDates  = request.getParameterValues("stockSubmissionDate[]");
      String[] stStatementDates   = request.getParameterValues("stockStatementDate[]");
      String[] stRawMatMargins    = request.getParameterValues("stockRawMatMargin[]");
      String[] stWipMargins       = request.getParameterValues("stockWorkInProMargin[]");
      String[] stFiniGoodsMargins = request.getParameterValues("stockFiniGoodsMargin[]");
      String[] stSecurityValues   = request.getParameterValues("stockSecurityValue[]");
      String[] stParticulars      = request.getParameterValues("stockParticular[]");

      if (stSecurityTypes != null && stSecurityTypes.length > 0) {
          String stSQL =
              "INSERT INTO APPLICATION.APPLICATIONSECURITYSTOCKSTATEM (" +
              "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, SUBMISSIONDATE, " +
              "DATEOFSTATEMENT, RAWMATERIALSTOCKVALUE, WIPVALUE, FINISHGOODSTOCKVALUE, " +
              "RELEASEDATE, SECURITYVALUE, PARTICULAR, " +
              "DATETIMESTAMP, CREATED_DATE, MODIFIED_DATE" +
              ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

          psStock = conn.prepareStatement(stSQL);
          int serial = 1;
          int validSt = 0;

          for (int i = 0; i < stSecurityTypes.length; i++) {
              String secType = trimSafe(stSecurityTypes[i]);
              if (secType == null || secType.isEmpty()) {
                  System.out.println("⚠️ Skip stock statement " + (i + 1) + " - empty security type");
                  continue;
              }

              System.out.println("✅ Stock Statement " + serial + ": " + secType);

              int c = 1;
              Timestamp stNow = new Timestamp(System.currentTimeMillis());

              psStock.setString(c++, applicationNumber);                                           // 1 APPLICATION_NUMBER
              psStock.setInt(c++, serial);                                                         // 2 SERIAL_NUMBER
              psStock.setString(c++, secType);                                                     // 3 SECURITYTYPE_CODE

              Date stSubDate = stSubmissionDates != null && i < stSubmissionDates.length
                               ? parseDate(stSubmissionDates[i]) : null;
              if (stSubDate != null) psStock.setDate(c++, stSubDate);
              else psStock.setNull(c++, Types.DATE);                                               // 4 SUBMISSIONDATE

              Date stStmtDate = stStatementDates != null && i < stStatementDates.length
                                ? parseDate(stStatementDates[i]) : null;
              if (stStmtDate != null) psStock.setDate(c++, stStmtDate);
              else psStock.setNull(c++, Types.DATE);                                               // 5 DATEOFSTATEMENT

              // Storing margin % values in stock value columns (form currently has no rupee fields)
              Double stRawMat = stRawMatMargins != null && i < stRawMatMargins.length
                                ? parseDouble(stRawMatMargins[i]) : null;
              if (stRawMat != null) psStock.setDouble(c++, stRawMat);
              else psStock.setNull(c++, Types.DECIMAL);                                            // 6 RAWMATERIALSTOCKVALUE

              Double stWip = stWipMargins != null && i < stWipMargins.length
                             ? parseDouble(stWipMargins[i]) : null;
              if (stWip != null) psStock.setDouble(c++, stWip);
              else psStock.setNull(c++, Types.DECIMAL);                                            // 7 WIPVALUE

              Double stFiniGoods = stFiniGoodsMargins != null && i < stFiniGoodsMargins.length
                                   ? parseDouble(stFiniGoodsMargins[i]) : null;
              if (stFiniGoods != null) psStock.setDouble(c++, stFiniGoods);
              else psStock.setNull(c++, Types.DECIMAL);                                            // 8 FINISHGOODSTOCKVALUE

              // RELEASEDATE — not in form, store null
              psStock.setNull(c++, Types.DATE);                                                    // 9 RELEASEDATE

              Double stSecVal = stSecurityValues != null && i < stSecurityValues.length
                                ? parseDouble(stSecurityValues[i]) : null;
              if (stSecVal != null) psStock.setDouble(c++, stSecVal);
              else psStock.setNull(c++, Types.DECIMAL);                                            // 10 SECURITYVALUE

              String stPart = stParticulars != null && i < stParticulars.length
                              ? trimSafe(stParticulars[i]) : null;
              if (stPart != null && !stPart.isEmpty()) psStock.setString(c++, stPart);
              else psStock.setNull(c++, Types.VARCHAR);                                            // 11 PARTICULAR

              psStock.setTimestamp(c++, stNow);                                                    // 12 DATETIMESTAMP
              psStock.setTimestamp(c++, stNow);                                                    // 13 CREATED_DATE
              psStock.setNull(c++, Types.TIMESTAMP);                                               // 14 MODIFIED_DATE

              psStock.addBatch();
              validSt++;
              serial++;
          }
          if (validSt > 0) {
              psStock.executeBatch();
              System.out.println("Stock Statement records inserted: " + validSt);
          }
      }

      // ================================================================
      // 14. INSERT SALARY  →  APPLICATION.APPLICATIONSECURITYSALARY
      // ================================================================
      // NOTE: This table has NO SERIAL_NUMBER column.
      String[] salSecurityTypes = request.getParameterValues("salarySecurityType[]");
      String[] salEmployeeNames = request.getParameterValues("salaryEmployeeName[]");
      String[] salAddr1         = request.getParameterValues("salaryAddress1[]");
      String[] salAddr2         = request.getParameterValues("salaryAddress2[]");
      String[] salAddr3         = request.getParameterValues("salaryAddress3[]");
      String[] salCities        = request.getParameterValues("salaryCity[]");
      String[] salStates        = request.getParameterValues("salaryState[]");
      String[] salCountries     = request.getParameterValues("salaryCountry[]");
      String[] salZips          = request.getParameterValues("salaryZip[]");
      String[] salPhones        = request.getParameterValues("salaryPhone[]");
      String[] salMobiles       = request.getParameterValues("salaryMobile[]");
      String[] salDepartments   = request.getParameterValues("salaryDepartment[]");
      String[] salGrossSalaries = request.getParameterValues("salaryGross[]");
      String[] salNetSalaries   = request.getParameterValues("salaryNet[]");
      String[] salPFAccounts    = request.getParameterValues("salaryPFAccount[]");
      String[] salPanNumbers    = request.getParameterValues("salaryPan[]");
      String[] salParticulars   = request.getParameterValues("salaryParticular[]");

      if (salSecurityTypes != null && salSecurityTypes.length > 0) {
          String salSQL =
              "INSERT INTO APPLICATION.APPLICATIONSECURITYSALARY (" +
              "APPLICATION_NUMBER, SECURITYTYPE_CODE, NAME, ADDRESS1, ADDRESS2, ADDRESS3, " +
              "CITY_CODE, STATE_CODE, COUNTRY_CODE, ZIP, PHONE, MOBILE, DEPARTMENT, " +
              "GROSSSALARY, NETSALARY, PFACCOUNTNUMBER, PANNUMBER, IS_INCOME_TAX_PAYEE, " +
              "PARTICULAR, DATETIMESTAMP, CREATED_DATE, MODIFIED_DATE" +
              ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

          psSalary = conn.prepareStatement(salSQL);
          int validSal = 0;

          for (int i = 0; i < salSecurityTypes.length; i++) {
              String secType = trimSafe(salSecurityTypes[i]);
              if (secType == null || secType.isEmpty()) {
                  System.out.println("⚠️ Skip salary " + (i + 1) + " - empty security type");
                  continue;
              }

              System.out.println("✅ Salary " + (i + 1) + ": " + secType);

              int c = 1;
              Timestamp salNow = new Timestamp(System.currentTimeMillis());

              psSalary.setString(c++, applicationNumber);                                          // 1 APPLICATION_NUMBER
              psSalary.setString(c++, secType);                                                    // 2 SECURITYTYPE_CODE

              psSalary.setString(c++, salEmployeeNames != null && i < salEmployeeNames.length
                                      ? trimSafe(salEmployeeNames[i]) : null);                     // 3 NAME

              psSalary.setString(c++, salAddr1 != null && i < salAddr1.length
                                      ? trimSafe(salAddr1[i]) : null);                             // 4 ADDRESS1
              psSalary.setString(c++, salAddr2 != null && i < salAddr2.length
                                      ? trimSafe(salAddr2[i]) : null);                             // 5 ADDRESS2
              psSalary.setString(c++, salAddr3 != null && i < salAddr3.length
                                      ? trimSafe(salAddr3[i]) : null);                             // 6 ADDRESS3

              // CITY_CODE is VARCHAR2(20) — NOT NULL
              String salCity = salCities != null && i < salCities.length ? trimSafe(salCities[i]) : null;
              if (salCity != null && !salCity.isEmpty()) psSalary.setString(c++, salCity);
              else psSalary.setString(c++, "NA");                                                  // 7 CITY_CODE

              // STATE_CODE is CHAR(20) — NOT NULL
              String salState = salStates != null && i < salStates.length ? trimSafe(salStates[i]) : null;
              if (salState != null && !salState.isEmpty()) psSalary.setString(c++, salState);
              else psSalary.setString(c++, "NA");                                                  // 8 STATE_CODE

              // COUNTRY_CODE is CHAR(2) — NOT NULL
              String salCountry = salCountries != null && i < salCountries.length ? trimSafe(salCountries[i]) : null;
              if (salCountry != null && salCountry.length() >= 2) psSalary.setString(c++, salCountry.substring(0, 2));
              else psSalary.setString(c++, "IN");                                                  // 9 COUNTRY_CODE

              Integer salZip = salZips != null && i < salZips.length ? parseInt(salZips[i]) : null;
              if (salZip != null && salZip != 0) psSalary.setInt(c++, salZip);
              else psSalary.setNull(c++, Types.INTEGER);                                           // 10 ZIP

              psSalary.setString(c++, salPhones != null && i < salPhones.length
                                      ? trimSafe(salPhones[i]) : null);                            // 11 PHONE
              psSalary.setString(c++, salMobiles != null && i < salMobiles.length
                                      ? trimSafe(salMobiles[i]) : null);                           // 12 MOBILE
              psSalary.setString(c++, salDepartments != null && i < salDepartments.length
                                      ? trimSafe(salDepartments[i]) : null);                       // 13 DEPARTMENT

              Double grossSal = salGrossSalaries != null && i < salGrossSalaries.length
                                ? parseDouble(salGrossSalaries[i]) : null;
              if (grossSal != null) psSalary.setDouble(c++, grossSal);
              else psSalary.setNull(c++, Types.DECIMAL);                                           // 14 GROSSSALARY

              Double netSal = salNetSalaries != null && i < salNetSalaries.length
                              ? parseDouble(salNetSalaries[i]) : null;
              if (netSal != null) psSalary.setDouble(c++, netSal);
              else psSalary.setNull(c++, Types.DECIMAL);                                           // 15 NETSALARY

              psSalary.setString(c++, salPFAccounts != null && i < salPFAccounts.length
                                      ? trimSafe(salPFAccounts[i]) : null);                        // 16 PFACCOUNTNUMBER
              psSalary.setString(c++, salPanNumbers != null && i < salPanNumbers.length
                                      ? trimSafe(salPanNumbers[i]) : null);                        // 17 PANNUMBER

              // IS_INCOME_TAX_PAYEE: radio button named salaryIsTaxPayer_N, value "Yes"/"No" → store "Y"/"N"
              // Since it uses indexed radio names (salaryIsTaxPayer_1, _2...), use a single param approach
              String taxPayerParam = request.getParameter("salaryIsTaxPayer_" + (i + 1));
              String isTaxPayee = "N";
              if ("Yes".equalsIgnoreCase(trimSafe(taxPayerParam))) {
                  isTaxPayee = "Y";
              }
              psSalary.setString(c++, isTaxPayee);                                                 // 18 IS_INCOME_TAX_PAYEE

              String salPart = salParticulars != null && i < salParticulars.length
                               ? trimSafe(salParticulars[i]) : null;
              if (salPart != null && !salPart.isEmpty()) psSalary.setString(c++, salPart);
              else psSalary.setNull(c++, Types.VARCHAR);                                           // 19 PARTICULAR

              psSalary.setTimestamp(c++, salNow);                                                  // 20 DATETIMESTAMP
              psSalary.setTimestamp(c++, salNow);                                                  // 21 CREATED_DATE
              psSalary.setNull(c++, Types.TIMESTAMP);                                              // 22 MODIFIED_DATE

              psSalary.addBatch();
              validSal++;
          }
          if (validSal > 0) {
              psSalary.executeBatch();
              System.out.println("Salary records inserted: " + validSal);
          }
      }
      
   // ================================================================
   // 15. INSERT MOTOR INSURANCE → APPLICATION.APPLICATIONMOTORSECURITY
   // ================================================================
   String[] motorSecurityTypes    = request.getParameterValues("motorSecurityType[]");
   String[] motorSubmissionDates  = request.getParameterValues("motorSubmissionDate[]");
   String[] motorIsNewVehicles    = request.getParameterValues("motorIsNewVehicle[]");
   String[] motorIsVehicleInsps   = request.getParameterValues("motorIsVehicleInsp[]");
   String[] motorMakeModels       = request.getParameterValues("motorMakeModel[]");
   String[] motorRegistrationNos  = request.getParameterValues("motorRegistrationNo[]");
   String[] motorChasisNos        = request.getParameterValues("motorChasisNo[]");
   String[] motorAcquisitionDates = request.getParameterValues("motorAcquisitionDate[]");
   String[] motorSupplierNames    = request.getParameterValues("motorSupplierName[]");
   String[] motorRegistrationDates= request.getParameterValues("motorRegistrationDate[]");
   String[] motorPurchasePrices   = request.getParameterValues("motorPurchasePrice[]");
   String[] motorMargins          = request.getParameterValues("motorMargin[]");
   String[] motorRTOLocations     = request.getParameterValues("motorRTOLocation[]");
   String[] motorCCs              = request.getParameterValues("motorCC[]");
   String[] motorSeatingCaps      = request.getParameterValues("motorSeatingCapacity[]");
   String[] motorCarryingCaps     = request.getParameterValues("motorCarryingCapacity[]");
   String[] motorPolicyStartDates = request.getParameterValues("motorPolicyStartDate[]");
   String[] motorPolicyEndDates   = request.getParameterValues("motorPolicyEndDate[]");
   String[] motorInsuranceValues  = request.getParameterValues("motorInsuranceValue[]");
   String[] motorNoClaimBOUs      = request.getParameterValues("motorNoClaimBOU[]");
   String[] motorPolicyTypes      = request.getParameterValues("motorPolicyType[]");
   String[] motorInsuranceNames   = request.getParameterValues("motorInsuranceName[]");
   String[] motorPolicyNos        = request.getParameterValues("motorPolicyNo[]");
   String[] motorPremiumAmounts   = request.getParameterValues("motorPremiumAmount[]");
   String[] motorTotalInsureds    = request.getParameterValues("motorTotalInsured[]");
   String[] motorPremiumFreqs     = request.getParameterValues("motorPremiumFreq[]");
   String[] motorModelYears       = request.getParameterValues("motorModelYear[]");
   String[] motorParticulars      = request.getParameterValues("motorParticular[]");

   if (motorSecurityTypes != null && motorSecurityTypes.length > 0) {
       String motorSQL =
           "INSERT INTO APPLICATION.APPLICATIONMOTORSECURITY (" +
           "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, SUBMISSIONDATE, " +
           "IS_NEW_VEHICLE, IS_VEHICLE_INSPECTED, VEHICLEMAKEMODEL, REGISTRATION_NUMBER, " +
           "CHASISNO, ACQUISITIONDATE, SUPPLIERNAME, REGISTRATIONDATE, " +
           "PURCHASEPRICE, MARGINEPERCENTAGE, RTOLOCATION, VEHICLECC, " +
           "SEATING_CAPACITY, CARRYING_CAPACITY, POLICY_STARTDATE, POLICY_ENDDATE, " +
           "DELEEASEDVALUE, NO_CLAIM_BOU, POLICYTYPE, INSURANCENAME, " +
           "POLICY_NUMBER, PREMIUMAMOUNT, INSUREDAMOUNT, PREMIUMFREQUENCY, " +
           "MODEL_YEAR, PARTICULAR" +
           ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

       psMotor = conn.prepareStatement(motorSQL);
       int serial = 1;
       int validMotor = 0;

       for (int i = 0; i < motorSecurityTypes.length; i++) {
           String secType = trimSafe(motorSecurityTypes[i]);
           if (secType == null || secType.isEmpty()) {
               System.out.println("⚠️ Skip motor insurance " + (i + 1) + " - empty security type");
               continue;
           }

           System.out.println("✅ Motor Insurance " + serial + ": " + secType);

           int c = 1;
           psMotor.setString(c++, applicationNumber);                                      // 1 APPLICATION_NUMBER
           psMotor.setInt(c++, serial);                                                    // 2 SERIAL_NUMBER
           psMotor.setString(c++, secType);                                                // 3 SECURITYTYPE_CODE

           Date mSubDate = motorSubmissionDates != null && i < motorSubmissionDates.length
                           ? parseDate(motorSubmissionDates[i]) : null;
           if (mSubDate != null) psMotor.setDate(c++, mSubDate);
           else psMotor.setNull(c++, Types.DATE);                                          // 4 SUBMISSIONDATE

           String isNewVehicle = motorIsNewVehicles != null && i < motorIsNewVehicles.length
                                 ? trimSafe(motorIsNewVehicles[i]) : "N";
           psMotor.setString(c++, (isNewVehicle != null && !isNewVehicle.isEmpty()) ? isNewVehicle : "N"); // 5 IS_NEW_VEHICLE

           String isVehicleInsp = motorIsVehicleInsps != null && i < motorIsVehicleInsps.length
                                  ? trimSafe(motorIsVehicleInsps[i]) : "N";
           psMotor.setString(c++, (isVehicleInsp != null && !isVehicleInsp.isEmpty()) ? isVehicleInsp : "N"); // 6 IS_VEHICLE_INSPECTED

           psMotor.setString(c++, motorMakeModels != null && i < motorMakeModels.length
                                  ? trimSafe(motorMakeModels[i]) : null);                 // 7 VEHICLEMAKEMODEL

           psMotor.setString(c++, motorRegistrationNos != null && i < motorRegistrationNos.length
                                  ? trimSafe(motorRegistrationNos[i]) : null);            // 8 REGISTRATION_NUMBER

           psMotor.setString(c++, motorChasisNos != null && i < motorChasisNos.length
                                  ? trimSafe(motorChasisNos[i]) : null);                  // 9 CHASISNO

           Date mAcqDate = motorAcquisitionDates != null && i < motorAcquisitionDates.length
                           ? parseDate(motorAcquisitionDates[i]) : null;
           if (mAcqDate != null) psMotor.setDate(c++, mAcqDate);
           else psMotor.setNull(c++, Types.DATE);                                          // 10 ACQUISITIONDATE

           psMotor.setString(c++, motorSupplierNames != null && i < motorSupplierNames.length
                                  ? trimSafe(motorSupplierNames[i]) : null);              // 11 SUPPLIERNAME

           Date mRegDate = motorRegistrationDates != null && i < motorRegistrationDates.length
                           ? parseDate(motorRegistrationDates[i]) : null;
           if (mRegDate != null) psMotor.setDate(c++, mRegDate);
           else psMotor.setNull(c++, Types.DATE);                                          // 12 REGISTRATIONDATE

           Double mPrice = motorPurchasePrices != null && i < motorPurchasePrices.length
                           ? parseDouble(motorPurchasePrices[i]) : null;
           if (mPrice != null) psMotor.setDouble(c++, mPrice);
           else psMotor.setNull(c++, Types.DECIMAL);                                       // 13 PURCHASEPRICE

           Double mMargin = motorMargins != null && i < motorMargins.length
                            ? parseDouble(motorMargins[i]) : null;
           if (mMargin != null) psMotor.setDouble(c++, mMargin);
           else psMotor.setNull(c++, Types.DECIMAL);                                       // 14 MARGINEPERCENTAGE

           psMotor.setString(c++, motorRTOLocations != null && i < motorRTOLocations.length
                                  ? trimSafe(motorRTOLocations[i]) : null);               // 15 RTOLOCATION

           Integer mCC = motorCCs != null && i < motorCCs.length
                         ? parseInt(motorCCs[i]) : null;
           if (mCC != null) psMotor.setInt(c++, mCC);
           else psMotor.setNull(c++, Types.INTEGER);                                       // 16 VEHICLECC

           Integer mSeating = motorSeatingCaps != null && i < motorSeatingCaps.length
                              ? parseInt(motorSeatingCaps[i]) : null;
           if (mSeating != null) psMotor.setInt(c++, mSeating);
           else psMotor.setNull(c++, Types.INTEGER);                                       // 17 SEATING_CAPACITY

           // CARRYING_CAPACITY is VARCHAR2(15) in the table
           psMotor.setString(c++, motorCarryingCaps != null && i < motorCarryingCaps.length
                                  ? trimSafe(motorCarryingCaps[i]) : null);               // 18 CARRYING_CAPACITY

           Date mPolStart = motorPolicyStartDates != null && i < motorPolicyStartDates.length
                            ? parseDate(motorPolicyStartDates[i]) : null;
           if (mPolStart != null) psMotor.setDate(c++, mPolStart);
           else psMotor.setNull(c++, Types.DATE);                                          // 19 POLICY_STARTDATE

           Date mPolEnd = motorPolicyEndDates != null && i < motorPolicyEndDates.length
                          ? parseDate(motorPolicyEndDates[i]) : null;
           if (mPolEnd != null) psMotor.setDate(c++, mPolEnd);
           else psMotor.setNull(c++, Types.DATE);                                          // 20 POLICY_ENDDATE

           Double mDelesedVal = motorInsuranceValues != null && i < motorInsuranceValues.length
                                ? parseDouble(motorInsuranceValues[i]) : null;
           if (mDelesedVal != null) psMotor.setDouble(c++, mDelesedVal);
           else psMotor.setNull(c++, Types.DECIMAL);                                       // 21 DELEEASEDVALUE

           Double mNoClaim = motorNoClaimBOUs != null && i < motorNoClaimBOUs.length
                             ? parseDouble(motorNoClaimBOUs[i]) : null;
           if (mNoClaim != null) psMotor.setDouble(c++, mNoClaim);
           else psMotor.setNull(c++, Types.DECIMAL);                                       // 22 NO_CLAIM_BOU

           psMotor.setString(c++, motorPolicyTypes != null && i < motorPolicyTypes.length
                                  ? trimSafe(motorPolicyTypes[i]) : null);                // 23 POLICYTYPE

           psMotor.setString(c++, motorInsuranceNames != null && i < motorInsuranceNames.length
                                  ? trimSafe(motorInsuranceNames[i]) : null);             // 24 INSURANCENAME

           psMotor.setString(c++, motorPolicyNos != null && i < motorPolicyNos.length
                                  ? trimSafe(motorPolicyNos[i]) : null);                  // 25 POLICY_NUMBER

           Double mPremAmt = motorPremiumAmounts != null && i < motorPremiumAmounts.length
                             ? parseDouble(motorPremiumAmounts[i]) : null;
           if (mPremAmt != null) psMotor.setDouble(c++, mPremAmt);
           else psMotor.setNull(c++, Types.DECIMAL);                                       // 26 PREMIUMAMOUNT

           Double mInsured = motorTotalInsureds != null && i < motorTotalInsureds.length
                             ? parseDouble(motorTotalInsureds[i]) : null;
           if (mInsured != null) psMotor.setDouble(c++, mInsured);
           else psMotor.setNull(c++, Types.DECIMAL);                                       // 27 INSUREDAMOUNT

           // PREMIUMFREQUENCY is CHAR(1) — map full word to single char
           String mFreqFull = motorPremiumFreqs != null && i < motorPremiumFreqs.length
                              ? trimSafe(motorPremiumFreqs[i]) : null;
           String mFreqCode = null;
           if (mFreqFull != null) {
               switch (mFreqFull) {
                   case "Monthly":     mFreqCode = "M"; break;
                   case "Quarterly":   mFreqCode = "Q"; break;
                   case "Half-Yearly": mFreqCode = "H"; break;
                   case "Yearly":      mFreqCode = "Y"; break;
                   default:            mFreqCode = mFreqFull.length() > 0
                                                   ? String.valueOf(mFreqFull.charAt(0)) : null;
               }
           }
           if (mFreqCode != null) psMotor.setString(c++, mFreqCode);
           else psMotor.setNull(c++, Types.CHAR);                                          // 28 PREMIUMFREQUENCY

           Integer mModelYear = motorModelYears != null && i < motorModelYears.length
                                ? parseInt(motorModelYears[i]) : null;
           if (mModelYear != null) psMotor.setInt(c++, mModelYear);
           else psMotor.setNull(c++, Types.INTEGER);                                       // 29 MODEL_YEAR

           String mParticular = motorParticulars != null && i < motorParticulars.length
                                ? trimSafe(motorParticulars[i]) : null;
           if (mParticular != null && !mParticular.isEmpty()) psMotor.setString(c++, mParticular);
           else psMotor.setNull(c++, Types.VARCHAR);                                       // 30 PARTICULAR

           psMotor.addBatch();
           validMotor++;
           serial++;
       }
       if (validMotor > 0) {
           psMotor.executeBatch();
           System.out.println("Motor Insurance records inserted: " + validMotor);
       }
   }
   
// ================================================================
// 16. INSERT OFFICE EQUIPMENT → APPLICATION.APPLICATIONSECURITYOFFICEEQUIP
// ================================================================
String[] officeSecurityTypes   = request.getParameterValues("officeSecurityType[]");
String[] officeIsNewArticles   = request.getParameterValues("officeIsNewArticle[]");
String[] officeMakeSerials     = request.getParameterValues("officeMakeSerial[]");
String[] officeMakeModels      = request.getParameterValues("officeMakeModel[]");
String[] officeSubmissionDates = request.getParameterValues("officeSubmissionDate[]");
String[] officeAcquisitionDates= request.getParameterValues("officeAcquisitionDate[]");
String[] officeWarrentyCards   = request.getParameterValues("officeWarrentyCard[]");
String[] officePurchasePrices  = request.getParameterValues("officePurchasePrice[]");
String[] officeMargins         = request.getParameterValues("officeMargin[]");
String[] officeArticleNames    = request.getParameterValues("officeArticleName[]");
String[] officeWarrentyMonths  = request.getParameterValues("officeWarrentyMonths[]");
String[] officeSecurityValues  = request.getParameterValues("officeSecurityValue[]");
String[] officeSupplierNames   = request.getParameterValues("officeSupplierName[]");
String[] officeParticulars     = request.getParameterValues("officeParticular[]");

if (officeSecurityTypes != null && officeSecurityTypes.length > 0) {
    String officeSQL =
        "INSERT INTO APPLICATION.APPLICATIONSECURITYOFFICEEQUIP (" +
        "APPLICATION_NUMBER, SERIAL_NUMBER, SECURITYTYPE_CODE, SUBMISSIONDATE, " +
        "NAMEOFARTICLE, MAKE, MAKESERIAL, DATEOFAQUISITION, " +
        "IS_NEW_ARTICLE, WARRANTYCARDNUMBER, WARRANTYINMONTHS, SUPPLIERNAME, " +
        "PURCHASEPRISE, MARGINPERCENTAGE, SECURITYVALUE, PARTICULAR, " +
        "CREATED_DATE, MODIFIED_DATE" +
        ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

    psOffice = conn.prepareStatement(officeSQL);
    int serial = 1;
    int validOffice = 0;

    for (int i = 0; i < officeSecurityTypes.length; i++) {
        String secType = trimSafe(officeSecurityTypes[i]);
        if (secType == null || secType.isEmpty()) {
            System.out.println("⚠️ Skip office equipment " + (i + 1) + " - empty security type");
            continue;
        }

        System.out.println("✅ Office Equipment " + serial + ": " + secType);

        int c = 1;
        Timestamp officeNow = new Timestamp(System.currentTimeMillis());

        psOffice.setString(c++, applicationNumber);                                     // 1 APPLICATION_NUMBER
        psOffice.setInt(c++, serial);                                                   // 2 SERIAL_NUMBER
        psOffice.setString(c++, secType);                                               // 3 SECURITYTYPE_CODE

        Date oSubDate = officeSubmissionDates != null && i < officeSubmissionDates.length
                        ? parseDate(officeSubmissionDates[i]) : null;
        if (oSubDate != null) psOffice.setDate(c++, oSubDate);
        else psOffice.setNull(c++, Types.DATE);                                         // 4 SUBMISSIONDATE

        // NAMEOFARTICLE is NOT NULL in DB
        String articleName = officeArticleNames != null && i < officeArticleNames.length
                             ? trimSafe(officeArticleNames[i]) : null;
        psOffice.setString(c++, (articleName != null && !articleName.isEmpty()) ? articleName : "NA"); // 5 NAMEOFARTICLE

        psOffice.setString(c++, officeMakeModels != null && i < officeMakeModels.length
                               ? trimSafe(officeMakeModels[i]) : null);                // 6 MAKE

        psOffice.setString(c++, officeMakeSerials != null && i < officeMakeSerials.length
                               ? trimSafe(officeMakeSerials[i]) : null);               // 7 MAKESERIAL

        Date oAcqDate = officeAcquisitionDates != null && i < officeAcquisitionDates.length
                        ? parseDate(officeAcquisitionDates[i]) : null;
        if (oAcqDate != null) psOffice.setDate(c++, oAcqDate);
        else psOffice.setNull(c++, Types.DATE);                                         // 8 DATEOFAQUISITION

        // IS_NEW_ARTICLE default 'N' in DB
        String isNewArticle = officeIsNewArticles != null && i < officeIsNewArticles.length
                              ? trimSafe(officeIsNewArticles[i]) : "N";
        psOffice.setString(c++, (isNewArticle != null && !isNewArticle.isEmpty()) ? isNewArticle : "N"); // 9 IS_NEW_ARTICLE

        psOffice.setString(c++, officeWarrentyCards != null && i < officeWarrentyCards.length
                               ? trimSafe(officeWarrentyCards[i]) : null);             // 10 WARRANTYCARDNUMBER

        Integer oWarMonths = officeWarrentyMonths != null && i < officeWarrentyMonths.length
                             ? parseInt(officeWarrentyMonths[i]) : null;
        if (oWarMonths != null) psOffice.setInt(c++, oWarMonths);
        else psOffice.setNull(c++, Types.INTEGER);                                      // 11 WARRANTYINMONTHS

        psOffice.setString(c++, officeSupplierNames != null && i < officeSupplierNames.length
                               ? trimSafe(officeSupplierNames[i]) : null);             // 12 SUPPLIERNAME

        Double oPrice = officePurchasePrices != null && i < officePurchasePrices.length
                        ? parseDouble(officePurchasePrices[i]) : null;
        if (oPrice != null) psOffice.setDouble(c++, oPrice);
        else psOffice.setNull(c++, Types.DECIMAL);                                      // 13 PURCHASEPRISE

        Double oMargin = officeMargins != null && i < officeMargins.length
                         ? parseDouble(officeMargins[i]) : null;
        if (oMargin != null) psOffice.setDouble(c++, oMargin);
        else psOffice.setNull(c++, Types.DECIMAL);                                      // 14 MARGINPERCENTAGE

        Double oSecVal = officeSecurityValues != null && i < officeSecurityValues.length
                         ? parseDouble(officeSecurityValues[i]) : null;
        if (oSecVal != null) psOffice.setDouble(c++, oSecVal);
        else psOffice.setNull(c++, Types.DECIMAL);                                      // 15 SECURITYVALUE

        String oPart = officeParticulars != null && i < officeParticulars.length
                       ? trimSafe(officeParticulars[i]) : null;
        if (oPart != null && !oPart.isEmpty()) psOffice.setString(c++, oPart);
        else psOffice.setNull(c++, Types.VARCHAR);                                      // 16 PARTICULAR

        psOffice.setTimestamp(c++, officeNow);                                          // 17 CREATED_DATE
        psOffice.setNull(c++, Types.TIMESTAMP);                                         // 18 MODIFIED_DATE

        psOffice.addBatch();
        validOffice++;
        serial++;
    }
    if (validOffice > 0) {
        psOffice.executeBatch();
        System.out.println("Office Equipment records inserted: " + validOffice);
    }
}

//================================================================
//17. INSERT NON-MOTOR INSURANCE → APPLICATION.APPLICATIONNONMOTORSECURITY
//================================================================
String[] nonmotorAddresses        = request.getParameterValues("nonmotorAddress[]");
String[] nonmotorRiskLocations    = request.getParameterValues("nonmotorRiskLocation[]");
String[] nonmotorPinCodes         = request.getParameterValues("nonmotorPinCode[]");
String[] nonmotorCities           = request.getParameterValues("nonmotorCity[]");
String[] nonmotorVillages         = request.getParameterValues("nonmotorVillage[]");
String[] nonmotorLandmarks        = request.getParameterValues("nonmotorLandmark[]");
String[] nonmotorPolicyStartDates = request.getParameterValues("nonmotorPolicyStartDate[]");
String[] nonmotorPolicyEndDates   = request.getParameterValues("nonmotorPolicyEndDate[]");
String[] nonmotorPropertyVals     = request.getParameterValues("nonmotorPropertyValuation[]");
String[] nonmotorInsCompanies     = request.getParameterValues("nonmotorInsuranceCompany[]");
String[] nonmotorExPolStarts      = request.getParameterValues("nonmotorExistingPolicyStart[]");
String[] nonmotorExPolEnds        = request.getParameterValues("nonmotorExistingPolicyEnd[]");
String[] nonmotorPremiumAmounts   = request.getParameterValues("nonmotorPremiumAmount[]");
String[] nonmotorMortgageTypes    = request.getParameterValues("nonmotorMortgageType[]");
String[] nonmotorMortgageDetails  = request.getParameterValues("nonmotorMortgageDetails[]");
String[] nonmotorMortgageVals     = request.getParameterValues("nonmotorMortgageValuation[]");

if (nonmotorAddresses != null && nonmotorAddresses.length > 0) {
 String nonMotorSQL =
     "INSERT INTO APPLICATION.APPLICATIONNONMOTORSECURITY (" +
     "APPLICATION_NUMBER, SERIAL_NUMBER, CORRESPONDANCE_ADDRESS, RISK_LOCATION, " +
     "PIN_CODE, CITY, VILLAGE, LANDMARK, " +
     "POLICY_STARTDATE, POLICY_ENDDATE, VALUATION_OF_PROPERTY, EX_INSURANCE_NAME, " +
     "EX_POLICY_START_DATE, EX_POLICY_END_DATE, PREMIUM_AMOUNT, TYPE_OF_MORTAGAGE, " +
     "MORTAGAGE_DETAILS, VALUATION_OF_MORTAGAGE, PURCHASE_DATE, NUMBEROFITEM, " +
     "POLICY_NUMBER, SUM_OF_INSURED" +
     ") VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

 psNonMotor = conn.prepareStatement(nonMotorSQL);
 int serial = 1;
 int validNonMotor = 0;

 for (int i = 0; i < nonmotorAddresses.length; i++) {
     String address = trimSafe(nonmotorAddresses[i]);
     if (address == null || address.isEmpty()) {
         System.out.println("⚠️ Skip non-motor insurance " + (i + 1) + " - empty address");
         continue;
     }

     System.out.println("✅ Non-Motor Insurance " + serial);

     int c = 1;
     psNonMotor.setString(c++, applicationNumber);                                   // 1 APPLICATION_NUMBER
     psNonMotor.setInt(c++, serial);                                                 // 2 SERIAL_NUMBER
     psNonMotor.setString(c++, address);                                             // 3 CORRESPONDANCE_ADDRESS

     psNonMotor.setString(c++, nonmotorRiskLocations != null && i < nonmotorRiskLocations.length
                               ? trimSafe(nonmotorRiskLocations[i]) : null);         // 4 RISK_LOCATION

     Integer nmPinCode = nonmotorPinCodes != null && i < nonmotorPinCodes.length
                         ? parseInt(nonmotorPinCodes[i]) : null;
     if (nmPinCode != null) psNonMotor.setInt(c++, nmPinCode);
     else psNonMotor.setNull(c++, Types.INTEGER);                                    // 5 PIN_CODE

     psNonMotor.setString(c++, nonmotorCities != null && i < nonmotorCities.length
                               ? trimSafe(nonmotorCities[i]) : null);                // 6 CITY

     psNonMotor.setString(c++, nonmotorVillages != null && i < nonmotorVillages.length
                               ? trimSafe(nonmotorVillages[i]) : null);              // 7 VILLAGE

     psNonMotor.setString(c++, nonmotorLandmarks != null && i < nonmotorLandmarks.length
                               ? trimSafe(nonmotorLandmarks[i]) : null);             // 8 LANDMARK

     Date nmPolStart = nonmotorPolicyStartDates != null && i < nonmotorPolicyStartDates.length
                       ? parseDate(nonmotorPolicyStartDates[i]) : null;
     if (nmPolStart != null) psNonMotor.setDate(c++, nmPolStart);
     else psNonMotor.setNull(c++, Types.DATE);                                       // 9 POLICY_STARTDATE

     Date nmPolEnd = nonmotorPolicyEndDates != null && i < nonmotorPolicyEndDates.length
                     ? parseDate(nonmotorPolicyEndDates[i]) : null;
     if (nmPolEnd != null) psNonMotor.setDate(c++, nmPolEnd);
     else psNonMotor.setNull(c++, Types.DATE);                                       // 10 POLICY_ENDDATE

     Double nmPropVal = nonmotorPropertyVals != null && i < nonmotorPropertyVals.length
                        ? parseDouble(nonmotorPropertyVals[i]) : null;
     if (nmPropVal != null) psNonMotor.setDouble(c++, nmPropVal);
     else psNonMotor.setNull(c++, Types.DECIMAL);                                    // 11 VALUATION_OF_PROPERTY

     psNonMotor.setString(c++, nonmotorInsCompanies != null && i < nonmotorInsCompanies.length
                               ? trimSafe(nonmotorInsCompanies[i]) : null);          // 12 EX_INSURANCE_NAME

     Date nmExPolStart = nonmotorExPolStarts != null && i < nonmotorExPolStarts.length
                         ? parseDate(nonmotorExPolStarts[i]) : null;
     if (nmExPolStart != null) psNonMotor.setDate(c++, nmExPolStart);
     else psNonMotor.setNull(c++, Types.DATE);                                       // 13 EX_POLICY_START_DATE

     Date nmExPolEnd = nonmotorExPolEnds != null && i < nonmotorExPolEnds.length
                       ? parseDate(nonmotorExPolEnds[i]) : null;
     if (nmExPolEnd != null) psNonMotor.setDate(c++, nmExPolEnd);
     else psNonMotor.setNull(c++, Types.DATE);                                       // 14 EX_POLICY_END_DATE

     Double nmPremAmt = nonmotorPremiumAmounts != null && i < nonmotorPremiumAmounts.length
                        ? parseDouble(nonmotorPremiumAmounts[i]) : null;
     if (nmPremAmt != null) psNonMotor.setDouble(c++, nmPremAmt);
     else psNonMotor.setNull(c++, Types.DECIMAL);                                    // 15 PREMIUM_AMOUNT

     psNonMotor.setString(c++, nonmotorMortgageTypes != null && i < nonmotorMortgageTypes.length
                               ? trimSafe(nonmotorMortgageTypes[i]) : null);         // 16 TYPE_OF_MORTAGAGE

     psNonMotor.setString(c++, nonmotorMortgageDetails != null && i < nonmotorMortgageDetails.length
                               ? trimSafe(nonmotorMortgageDetails[i]) : null);       // 17 MORTAGAGE_DETAILS

     Double nmMortgageVal = nonmotorMortgageVals != null && i < nonmotorMortgageVals.length
                            ? parseDouble(nonmotorMortgageVals[i]) : null;
     if (nmMortgageVal != null) psNonMotor.setDouble(c++, nmMortgageVal);
     else psNonMotor.setNull(c++, Types.DECIMAL);                                    // 18 VALUATION_OF_MORTAGAGE

     psNonMotor.setNull(c++, Types.DATE);                                            // 19 PURCHASE_DATE (no JSP field)
     psNonMotor.setNull(c++, Types.INTEGER);                                         // 20 NUMBEROFITEM (no JSP field)
     psNonMotor.setNull(c++, Types.VARCHAR);                                         // 21 POLICY_NUMBER (no JSP field)
     psNonMotor.setNull(c++, Types.DECIMAL);                                         // 22 SUM_OF_INSURED (no JSP field)

     psNonMotor.addBatch();
     validNonMotor++;
     serial++;
 }
 if (validNonMotor > 0) {
     psNonMotor.executeBatch();
     System.out.println("Non-Motor Insurance records inserted: " + validNonMotor);
 }
}

//================================================================
//18. INSERT GOVERNMENT SECURITY → APPLICATION.APPLICATIONGOVTCERTSECURITY
//================================================================
String[] govSecTerms         = request.getParameterValues("govSecTerms[]");
String[] govSecCertNos       = request.getParameterValues("govSecCertNo[]");
String[] govSecCertDates     = request.getParameterValues("govSecCertDate[]");
String[] govSecMaturityDates = request.getParameterValues("govSecMaturityDate[]");
String[] govSecMaturityAmts  = request.getParameterValues("govSecMaturityAmount[]");
String[] govSecCertAmts      = request.getParameterValues("govSecCertAmount[]");
String[] govSecNominees      = request.getParameterValues("govSecNominee[]");
String[] govSecTransferables = request.getParameterValues("govSecTransferable[]");

if (govSecTerms != null && govSecTerms.length > 0) {
 String govSecSQL =
     "INSERT INTO APPLICATION.APPLICATIONGOVTCERTSECURITY (" +
     "APPLICATION_NUMBER, SERIAL_NUMBER, TERMS, CERTIFICATE_NUMBER, " +
     "CERTIFICATE_DATE, CERTIFICATE_AMOUNT, MATURITY_DATE, MATURITY_AMOUNT, " +
     "IS_TRANSFERABLE, NOMINEE" +
     ") VALUES (?,?,?,?,?,?,?,?,?,?)";

 psGovSec = conn.prepareStatement(govSecSQL);
 int serial = 1;
 int validGovSec = 0;

 for (int i = 0; i < govSecTerms.length; i++) {
     String terms = trimSafe(govSecTerms[i]);
     if (terms == null || terms.isEmpty()) {
         System.out.println("⚠️ Skip gov security " + (i + 1) + " - empty terms");
         continue;
     }

     System.out.println("✅ Gov Security " + serial + ": " + terms);

     int c = 1;
     psGovSec.setString(c++, applicationNumber);                                     // 1 APPLICATION_NUMBER
     psGovSec.setInt(c++, serial);                                                   // 2 SERIAL_NUMBER

     // TERMS is CHAR(40) NOT NULL — truncate if needed
     psGovSec.setString(c++, terms.length() > 40 ? terms.substring(0, 40) : terms); // 3 TERMS

     // CERTIFICATE_NUMBER is NUMBER(14,0) — parse as Long
     String certNoStr = govSecCertNos != null && i < govSecCertNos.length
                        ? trimSafe(govSecCertNos[i]) : null;
     if (certNoStr != null && !certNoStr.isEmpty()) {
         try { psGovSec.setLong(c++, Long.parseLong(certNoStr)); }
         catch (NumberFormatException e) { psGovSec.setNull(c++, Types.NUMERIC); }
     } else {
         psGovSec.setNull(c++, Types.NUMERIC);                                       // 4 CERTIFICATE_NUMBER
     }

     Date gCertDate = govSecCertDates != null && i < govSecCertDates.length
                      ? parseDate(govSecCertDates[i]) : null;
     if (gCertDate != null) psGovSec.setDate(c++, gCertDate);
     else psGovSec.setNull(c++, Types.DATE);                                         // 5 CERTIFICATE_DATE

     Double certAmt = govSecCertAmts != null && i < govSecCertAmts.length
                      ? parseDouble(govSecCertAmts[i]) : null;
     if (certAmt != null) psGovSec.setDouble(c++, certAmt);
     else psGovSec.setNull(c++, Types.DECIMAL);                                      // 6 CERTIFICATE_AMOUNT

     Date gMatDate = govSecMaturityDates != null && i < govSecMaturityDates.length
                     ? parseDate(govSecMaturityDates[i]) : null;
     if (gMatDate != null) psGovSec.setDate(c++, gMatDate);
     else psGovSec.setNull(c++, Types.DATE);                                         // 7 MATURITY_DATE

     Double matAmt = govSecMaturityAmts != null && i < govSecMaturityAmts.length
                     ? parseDouble(govSecMaturityAmts[i]) : null;
     if (matAmt != null) psGovSec.setDouble(c++, matAmt);
     else psGovSec.setNull(c++, Types.DECIMAL);                                      // 8 MATURITY_AMOUNT

     // IS_TRANSFERABLE — checkbox sends "Y" when checked, nothing when unchecked
     // govSecTransferables[] only contains values for checked boxes, so check by index
     String isTransferable = govSecTransferables != null && i < govSecTransferables.length
                             ? trimSafe(govSecTransferables[i]) : null;
     if (isTransferable != null && !isTransferable.isEmpty()) psGovSec.setString(c++, "Y");
     else psGovSec.setString(c++, "N");                                              // 9 IS_TRANSFERABLE

     String nominee = govSecNominees != null && i < govSecNominees.length
                      ? trimSafe(govSecNominees[i]) : null;
     if (nominee != null && !nominee.isEmpty()) psGovSec.setString(c++, nominee);
     else psGovSec.setNull(c++, Types.CHAR);                                         // 10 NOMINEE

     psGovSec.addBatch();
     validGovSec++;
     serial++;
 }
 if (validGovSec > 0) {
     psGovSec.executeBatch();
     System.out.println("Gov Security records inserted: " + validGovSec);
 }
}

            // ================================================================
            // COMMIT
            // ================================================================
            conn.commit();
            System.out.println("✅ Transaction committed. Application: " + applicationNumber);

            response.sendRedirect("loan.jsp?status=success&applicationNumber=" +
                                  applicationNumber + "&productCode=" + productCode);

        } catch (Exception e) {
            if (conn != null) {
                try { conn.rollback(); } catch (Exception ignored) {}
            }
            e.printStackTrace();
            response.sendRedirect("loan.jsp?status=error&message=" +
                java.net.URLEncoder.encode(e.getMessage() != null ? e.getMessage() : "Unknown error", "UTF-8") +
                "&productCode=" + (productCode != null ? productCode : ""));

        } finally {
            try { if (psApp          != null) psApp.close();          } catch (Exception ignored) {}
            try { if (psLoan         != null) psLoan.close();         } catch (Exception ignored) {}
            try { if (psNominee      != null) psNominee.close();      } catch (Exception ignored) {}
            try { if (psCoBorrower   != null) psCoBorrower.close();   } catch (Exception ignored) {}
            try { if (psGuarantor    != null) psGuarantor.close();    } catch (Exception ignored) {}
            try { if (psLandBuild    != null) psLandBuild.close();    } catch (Exception ignored) {}
            try { if (psDeposit      != null) psDeposit.close();      } catch (Exception ignored) {}
            try { if (psGold         != null) psGold.close();         } catch (Exception ignored) {}
            try { if (psPlant        != null) psPlant.close();        } catch (Exception ignored) {}
            try { if (psVehicle      != null) psVehicle.close();      } catch (Exception ignored) {}
            try { if (psInsurance    != null) psInsurance.close();    } catch (Exception ignored) {}
            try { if (psMarketShares != null) psMarketShares.close(); } catch (Exception ignored) {}
            try { if (psStock        != null) psStock.close();        } catch (Exception ignored) {}
            try { if (psSalary       != null) psSalary.close();       } catch (Exception ignored) {}
            try { if (psMotor        != null) psMotor.close();        } catch (Exception ignored) {}
            try { if (psOffice       != null) psOffice.close();       } catch (Exception ignored) {}
            try { if (psNonMotor     != null) psNonMotor.close();     } catch (Exception ignored) {}
            try { if (psGovSec       != null) psGovSec.close();       } catch (Exception ignored) {}
            
            try {
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                }
            } catch (Exception ignored) {}
        }
    }
}