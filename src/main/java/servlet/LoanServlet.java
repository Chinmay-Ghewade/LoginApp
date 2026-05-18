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
        PreparedStatement psApp        = null;
        PreparedStatement psLoan       = null;
        PreparedStatement psNominee    = null;
        PreparedStatement psCoBorrower = null;
        PreparedStatement psGuarantor  = null;
        PreparedStatement psLandBuild  = null;
        PreparedStatement psDeposit    = null;
        PreparedStatement psGold       = null;
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
            try { if (psApp        != null) psApp.close();        } catch (Exception ignored) {}
            try { if (psLoan       != null) psLoan.close();       } catch (Exception ignored) {}
            try { if (psNominee    != null) psNominee.close();    } catch (Exception ignored) {}
            try { if (psCoBorrower != null) psCoBorrower.close(); } catch (Exception ignored) {}
            try { if (psGuarantor  != null) psGuarantor.close();  } catch (Exception ignored) {}
            try { if (psLandBuild  != null) psLandBuild.close();  } catch (Exception ignored) {}
            try { if (psDeposit    != null) psDeposit.close();    } catch (Exception ignored) {}
            try { if (psGold       != null) psGold.close();       } catch (Exception ignored) {}
            try {
                if (conn != null) {
                    conn.setAutoCommit(true);
                    conn.close();
                }
            } catch (Exception ignored) {}
        }
    }
}