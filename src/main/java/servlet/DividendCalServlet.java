package servlet;

import db.DBConnection;

import com.lowagie.text.*;
import com.lowagie.text.pdf.*;
import com.lowagie.text.pdf.PdfPTable;
import com.lowagie.text.pdf.PdfPCell;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.*;
import java.awt.Color;
import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.text.SimpleDateFormat;
import java.util.Date;

@WebServlet("/dividendCal")
public class DividendCalServlet extends HttpServlet {

    // ── Safe string for JSON ──
    private String jsonSafe(String s) {
        if (s == null) return "";
        return s.trim()
                .replace("\\", "\\\\")
                .replace("\"", "\\\"")
                .replace("\r", "")
                .replace("\n", "");
    }

    private String jsonSafeErr(Exception e) {
        String msg = e.getMessage();
        if (msg == null) msg = "DB error";
        return msg.replace("\"", "'").replace("\r", "").replace("\n", " ");
    }

    private String nvl(String s) { return s == null ? "" : s.trim(); }

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException { doPost(req, res); }

    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession sess = req.getSession(false);
        if (sess == null || sess.getAttribute("branchCode") == null) {
            res.sendRedirect(req.getContextPath() + "/login.jsp");
            return;
        }

        String action     = nvl(req.getParameter("action"));
        String branchCode = nvl((String) sess.getAttribute("branchCode"));
        String userId     = nvl((String) sess.getAttribute("userId"));

        // ── PDF action: streams binary, does NOT use JSON writer ──
        if ("reportPDF".equals(action)) {
            generatePDF(req, res, branchCode, userId);
            return;
        }

        res.reset();
        res.setContentType("application/json; charset=UTF-8");
        PrintWriter pw = res.getWriter();

        try {
            switch (action) {
                case "getMemberTypes": getMemberTypes(pw);                              break;
                case "getAccounts":    getAccounts(req, pw);                            break;
                case "calculate":      calculate(req, pw, branchCode, userId);          break;
                case "report":         report(req, pw, branchCode);                     break;
                case "postingPayable": postingPayable(req, pw, branchCode, userId);     break;
                case "postingSB":      postingSB(req, pw, branchCode, userId);          break;
                default:               pw.print("{\"success\":false,\"message\":\"Unknown action\"}");
            }
        } finally {
            pw.flush();
        }
    }

    // ══════════════════════════════════════════
    // ACTION 1 — Get Member Types for Lookup Popup
    // SUBSTR(ACCOUNT_NUMBER, 5, 3) extracts product code (901/902)
    // from account number format e.g. 00029020051055 → 902
    // Only STATUS = 'A' active accounts
    // ══════════════════════════════════════════
    private void getMemberTypes(PrintWriter pw) {
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        StringBuilder sb = new StringBuilder("[");
        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT DISTINCT SUBSTR(ACCOUNT_NUMBER, 5, 3) AS PRODUCT_CODE, " +
                "       MEMBER_TYPE " +
                "FROM SHARES.CERTIFICATE_MASTER " +
                "WHERE MEMBER_TYPE IN ('A','B') " +
                "AND   STATUS = 'A' " +
                "AND   ACCOUNT_NUMBER IS NOT NULL " +
                "ORDER BY MEMBER_TYPE, SUBSTR(ACCOUNT_NUMBER, 5, 3)";
            ps = conn.prepareStatement(sql);
            rs = ps.executeQuery();
            boolean first = true;
            while (rs.next()) {
                if (!first) sb.append(",");
                sb.append("{")
                  .append("\"productCode\":\"").append(jsonSafe(rs.getString("PRODUCT_CODE"))).append("\",")
                  .append("\"memberType\":\"").append(jsonSafe(rs.getString("MEMBER_TYPE"))).append("\"")
                  .append("}");
                first = false;
            }
            sb.append("]");
            pw.print(sb.toString());
        } catch (Exception e) {
            // FIX 4: Return error object instead of silently swallowing the exception.
            // Previously returned "[]" which made the dropdown appear empty with no feedback.
            pw.print("{\"error\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 2 — Get count of active accounts
    // Filters by MEMBER_TYPE and SUBSTR(ACCOUNT_NUMBER,5,3) = productCode
    // Only STATUS = 'A'
    // ══════════════════════════════════════════
    private void getAccounts(HttpServletRequest req, PrintWriter pw) {
        String memberType  = nvl(req.getParameter("memberType"));
        String productCode = nvl(req.getParameter("productCode"));
        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;
        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT COUNT(*) AS total " +
                "FROM SHARES.CERTIFICATE_MASTER " +
                "WHERE MEMBER_TYPE = ? " +
                "AND   SUBSTR(ACCOUNT_NUMBER, 5, 3) = ? " +
                "AND   STATUS = 'A'";
            ps = conn.prepareStatement(sql);
            ps.setString(1, memberType);
            ps.setString(2, productCode);
            rs = ps.executeQuery();
            int count = 0;
            if (rs.next()) count = rs.getInt("total");
            pw.print("{\"success\":true,\"count\":" + count + ",\"memberType\":\"" + jsonSafe(memberType) + "\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 3 — Calculate Dividend
    // Calls sp_dividend_calc stored procedure
    // ══════════════════════════════════════════
    private void calculate(HttpServletRequest req, PrintWriter pw,
                           String branchCode, String userId) {
        String productCode = nvl(req.getParameter("productCode"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        CallableStatement cs = null;
        try {
            conn = DBConnection.getConnection();
            // sp_dividend_calc(branch, working_date, div_bal_date, y_begin, y_end, mem_product)
            cs = conn.prepareCall("{call sp_dividend_calc(?,?,?,?,?,?)}");
            cs.setString(1, branchCode);
            // FIX 2: p_working_date must be today's actual date, not yearBegin.
            // Previously yearBegin was passed for both param 2 (working_date) and param 4 (y_begin_date),
            // which caused sp_dividend_pay to skip posting because its date guard
            // (IF p_working_date = v_div_post_date) never matched.
            cs.setDate(2, new java.sql.Date(new java.util.Date().getTime()));
            cs.setDate(3, java.sql.Date.valueOf(divBalDate));
            cs.setDate(4, java.sql.Date.valueOf(yearBegin));
            cs.setDate(5, java.sql.Date.valueOf(yearEnd));
            cs.setString(6, productCode);
            cs.execute();
            pw.print("{\"success\":true,\"message\":\"Dividend calculated successfully for product " + jsonSafe(productCode) + "\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(null, cs, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 4 — Report (JSON for on-screen grid)
    // Reads from shares.dividend_calc
    //
    // FIX 1: Filter by PRODUCT CODE (e.g. '901'/'902'), NOT member type letter ('A'/'B').
    // sp_dividend_calc inserts p_mem_product_type (the product code) into the MEMBER_TYPE
    // column of dividend_calc. The old code passed memberType ('A'/'B') which never
    // matched the stored product code — causing the report to always return 0 rows.
    // ══════════════════════════════════════════
    private void report(HttpServletRequest req, PrintWriter pw, String branchCode) {
        String productCode = nvl(req.getParameter("productCode"));
        String memberType  = nvl(req.getParameter("memberType"));  // kept for reference/summary only
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        PreparedStatement ps = null;
        ResultSet rs       = null;
        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT MEMBER_CODE, PAYABLE_AC, CR_ACCOUNT_CODE, " +
                "       BAL_SHARES_FOR_DIV, CURR_BALANCE, DIV_PERCENTAGE, " +
                "       DIV_AMOUNT, DIV_AMOUNT_POST, DIV_WARR_NO, " +
                "       NVL(PAYABLE_TXN_NO,0) AS PAYABLE_TXN_NO, " +
                "       TO_CHAR(PAYABLE_TXN_DATE,'DD-MM-YYYY') AS PAYABLE_TXN_DATE " +
                "FROM shares.dividend_calc " +
                "WHERE BRANCH_CODE = ? " +
                "AND Y_BEGIN_DATE  = TO_DATE(?,'YYYY-MM-DD') " +
                "AND Y_END_DATE    = TO_DATE(?,'YYYY-MM-DD') " +
                "AND DIV_BAL_DATE  = TO_DATE(?,'YYYY-MM-DD') " +
                // FIX 1: Use productCode here — the procedure stores product code ('901'/'902')
                // in MEMBER_TYPE column, not the letter ('A'/'B').
                "AND MEMBER_TYPE   = ? " +
                "ORDER BY MEMBER_CODE";
            ps = conn.prepareStatement(sql);
            ps.setString(1, branchCode);
            ps.setString(2, yearBegin);
            ps.setString(3, yearEnd);
            ps.setString(4, divBalDate);
            ps.setString(5, productCode);   // FIX 1: was memberType, now productCode
            rs = ps.executeQuery();
            double total = 0;
            int count = 0;
            StringBuilder rows = new StringBuilder("[");
            boolean first = true;
            while (rs.next()) {
                if (!first) rows.append(",");
                double amt = rs.getDouble("DIV_AMOUNT_POST");
                total += amt;
                count++;
                rows.append("{")
                    .append("\"memberCode\":\"").append(jsonSafe(rs.getString("MEMBER_CODE"))).append("\",")
                    .append("\"payableAc\":\"").append(jsonSafe(rs.getString("PAYABLE_AC"))).append("\",")
                    .append("\"crAccountCode\":\"").append(jsonSafe(rs.getString("CR_ACCOUNT_CODE"))).append("\",")
                    .append("\"balForDiv\":").append(rs.getDouble("BAL_SHARES_FOR_DIV")).append(",")
                    .append("\"currBalance\":").append(rs.getDouble("CURR_BALANCE")).append(",")
                    .append("\"divPercentage\":").append(rs.getDouble("DIV_PERCENTAGE")).append(",")
                    .append("\"divAmount\":").append(rs.getDouble("DIV_AMOUNT")).append(",")
                    .append("\"divAmountPost\":").append(amt).append(",")
                    .append("\"divWarrNo\":").append(rs.getLong("DIV_WARR_NO")).append(",")
                    .append("\"payableTxnNo\":").append(rs.getLong("PAYABLE_TXN_NO")).append(",")
                    .append("\"payableTxnDate\":\"").append(jsonSafe(rs.getString("PAYABLE_TXN_DATE"))).append("\"")
                    .append("}");
                first = false;
            }
            rows.append("]");
            pw.print("{\"success\":true,\"count\":" + count + ",\"total\":" + total + ",\"rows\":" + rows + "}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 7 — Generate PDF Report
    // Streams a PDF directly to the browser (opens in new tab via JS window.open)
    // Uses OpenPDF (com.github.librepdf:openpdf) — drop openpdf-x.x.x.jar in WEB-INF/lib
    //
    // FIX 3: Filter by productCode (not memberType) — same root cause as report() fix.
    // ══════════════════════════════════════════
    private void generatePDF(HttpServletRequest req, HttpServletResponse res,
                              String branchCode, String userId) throws IOException {

        String productCode = nvl(req.getParameter("productCode"));
        String memberType  = nvl(req.getParameter("memberType"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        String percentage  = nvl(req.getParameter("percentage"));

        Connection conn = null;
        PreparedStatement ps = null;
        ResultSet rs = null;

        // ── Colour palette matching the UI theme ──
        Color NAVY      = new Color(0x1a, 0x14, 0x64);
        Color LAVENDER  = new Color(0xE6, 0xE6, 0xFA);
        Color WHITE     = Color.WHITE;
        Color ORANGE    = new Color(0xEF, 0x9F, 0x27);
        Color GREEN_BD  = new Color(0x5D, 0xCA, 0xA5);
        Color GREEN_BG  = new Color(0xE0, 0xF5, 0xEA);
        Color ORANGE_BG = new Color(0xFF, 0xF5, 0xE0);

        try {
            conn = DBConnection.getConnection();
            String sql =
                "SELECT MEMBER_CODE, PAYABLE_AC, CR_ACCOUNT_CODE, " +
                "       BAL_SHARES_FOR_DIV, CURR_BALANCE, DIV_PERCENTAGE, " +
                "       DIV_AMOUNT, DIV_AMOUNT_POST, DIV_WARR_NO, " +
                "       NVL(PAYABLE_TXN_NO,0) AS PAYABLE_TXN_NO, " +
                "       TO_CHAR(PAYABLE_TXN_DATE,'DD-MM-YYYY') AS PAYABLE_TXN_DATE " +
                "FROM shares.dividend_calc " +
                "WHERE BRANCH_CODE = ? " +
                "AND Y_BEGIN_DATE  = TO_DATE(?,'YYYY-MM-DD') " +
                "AND Y_END_DATE    = TO_DATE(?,'YYYY-MM-DD') " +
                "AND DIV_BAL_DATE  = TO_DATE(?,'YYYY-MM-DD') " +
                // FIX 3: Use productCode here — same fix as report(). The procedure stores
                // product code ('901'/'902') in MEMBER_TYPE, not the letter ('A'/'B').
                "AND MEMBER_TYPE   = ? " +
                "ORDER BY MEMBER_CODE";
            ps = conn.prepareStatement(sql);
            ps.setString(1, branchCode);
            ps.setString(2, yearBegin);
            ps.setString(3, yearEnd);
            ps.setString(4, divBalDate);
            ps.setString(5, productCode);   // FIX 3: was memberType, now productCode
            rs = ps.executeQuery();

            // ── collect rows first (need count/total for header) ──
            java.util.List<Object[]> dataRows = new java.util.ArrayList<>();
            double grandTotal = 0;
            while (rs.next()) {
                double amt = rs.getDouble("DIV_AMOUNT_POST");
                grandTotal += amt;
                dataRows.add(new Object[]{
                    rs.getString("MEMBER_CODE"),
                    rs.getString("PAYABLE_AC"),
                    rs.getString("CR_ACCOUNT_CODE"),
                    rs.getDouble("BAL_SHARES_FOR_DIV"),
                    rs.getDouble("DIV_PERCENTAGE"),
                    rs.getDouble("DIV_AMOUNT"),
                    amt,
                    rs.getLong("DIV_WARR_NO"),
                    rs.getLong("PAYABLE_TXN_NO"),
                    rs.getString("PAYABLE_TXN_DATE")
                });
            }

            // ── stream PDF ──
            res.reset();
            res.setContentType("application/pdf");
            res.setHeader("Content-Disposition",
                "inline; filename=\"DividendReport_" + productCode + "_" + yearBegin + ".pdf\"");

            Document doc = new Document(PageSize.A4.rotate(), 28, 28, 36, 28);
            PdfWriter writer = PdfWriter.getInstance(doc, res.getOutputStream());

            // ── Page number footer via page events ──
            writer.setPageEvent(new PdfPageEventHelper() {
                Font footFont = FontFactory.getFont(FontFactory.HELVETICA, 7, Color.GRAY);
                @Override
                public void onEndPage(PdfWriter w, Document d) {
                    PdfContentByte cb = w.getDirectContent();
                    String footLeft  = "Generated: " + new SimpleDateFormat("dd-MM-yyyy HH:mm").format(new Date())
                                       + "  |  shares.dividend_calc";
                    String footRight = "** System Generated Report **    Page " + w.getPageNumber();
                    ColumnText.showTextAligned(cb, Element.ALIGN_LEFT,
                        new Phrase(footLeft, footFont),
                        d.leftMargin(), d.bottomMargin() - 10, 0);
                    ColumnText.showTextAligned(cb, Element.ALIGN_RIGHT,
                        new Phrase(footRight, footFont),
                        d.right() - d.rightMargin(), d.bottomMargin() - 10, 0);
                }
            });

            doc.open();

            Font titleFont   = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 13, WHITE);
            Font subFont     = FontFactory.getFont(FontFactory.HELVETICA,      9,  WHITE);
            Font boldSmall   = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8,  NAVY);
            Font normalSmall = FontFactory.getFont(FontFactory.HELVETICA,      8,  NAVY);
            Font colHdr      = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7,  WHITE);
            Font cellFont    = FontFactory.getFont(FontFactory.HELVETICA,      7,  NAVY);
            Font cellFontB   = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 7,  NAVY);
            Font footTotFont = FontFactory.getFont(FontFactory.HELVETICA_BOLD, 8,  WHITE);

            // ── HEADER BANNER ──
            PdfPTable banner = new PdfPTable(2);
            banner.setWidthPercentage(100);
            banner.setWidths(new float[]{3f, 1.6f});
            banner.setSpacingAfter(8);

            PdfPCell orgCell = new PdfPCell();
            orgCell.setBackgroundColor(NAVY);
            orgCell.setBorder(Rectangle.NO_BORDER);
            orgCell.setPadding(10);
            orgCell.addElement(new Phrase("Co-operative Bank", titleFont));
            orgCell.addElement(new Phrase("Shares Division  —  Dividend Calculation Report", subFont));
            banner.addCell(orgCell);

            String today = new SimpleDateFormat("dd-MM-yyyy").format(new Date());
            PdfPCell metaCell = new PdfPCell();
            metaCell.setBackgroundColor(NAVY);
            metaCell.setBorder(Rectangle.NO_BORDER);
            metaCell.setPadding(10);
            metaCell.setHorizontalAlignment(Element.ALIGN_RIGHT);
            metaCell.addElement(new Phrase("Branch : " + branchCode + "    User : " + userId, subFont));
            metaCell.addElement(new Phrase("Date   : " + today, subFont));
            banner.addCell(metaCell);
            doc.add(banner);

            // ── SUMMARY PILLS ──
            PdfPTable summary = new PdfPTable(8);
            summary.setWidthPercentage(100);
            summary.setSpacingAfter(10);
            String[] sumLabels = {
                "Product Code", "Member Type", "Year Begin", "Year End",
                "Div Bal Date", "Rate %", "Total Members", "Total Dividend"
            };
            String yb  = fmtDate(yearBegin);
            String ye  = fmtDate(yearEnd);
            String dbd = fmtDate(divBalDate);
            String[] sumVals = {
                productCode, memberType, yb, ye, dbd, percentage + "%",
                String.valueOf(dataRows.size()),
                "\u20B9 " + String.format("%,.2f", grandTotal)
            };
            for (int i = 0; i < sumLabels.length; i++) {
                PdfPCell sc = new PdfPCell();
                sc.setBackgroundColor(LAVENDER);
                sc.setBorderColor(new Color(0xB8, 0xB8, 0xE6));
                sc.setBorderWidth(0.5f);
                sc.setPadding(5);
                sc.addElement(new Phrase(sumLabels[i], FontFactory.getFont(FontFactory.HELVETICA, 6.5f, NAVY)));
                sc.addElement(new Phrase(sumVals[i],   boldSmall));
                summary.addCell(sc);
            }
            doc.add(summary);

            // ── DATA TABLE ──
            PdfPTable tbl = new PdfPTable(11);
            tbl.setWidthPercentage(100);
            tbl.setWidths(new float[]{0.5f, 1.4f, 1.8f, 1.8f, 1.4f, 0.7f, 1.3f, 1.3f, 1.0f, 0.9f, 1.1f});
            tbl.setHeaderRows(1);

            String[] headers = {
                "#", "Member Code", "Payable Account", "SB Account",
                "Bal for Div (\u20B9)", "Rate %",
                "Div Amount (\u20B9)", "Post Amount (\u20B9)",
                "Warrant No", "Status", "Txn Date"
            };
            for (String h : headers) {
                PdfPCell hc = new PdfPCell(new Phrase(h, colHdr));
                hc.setBackgroundColor(NAVY);
                hc.setBorder(Rectangle.NO_BORDER);
                hc.setPaddingTop(5);
                hc.setPaddingBottom(5);
                hc.setPaddingLeft(4);
                hc.setPaddingRight(4);
                hc.setHorizontalAlignment(Element.ALIGN_CENTER);
                tbl.addCell(hc);
            }

            int sr = 0;
            for (Object[] row : dataRows) {
                sr++;
                Color bg = (sr % 2 == 0) ? new Color(0xF0, 0xF0, 0xFA) : WHITE;

                String  memCode  = nvlStr(row[0]);
                String  payAc    = nvlStr(row[1]);
                String  crAc     = nvlStr(row[2]);
                double  bal      = (Double)  row[3];
                double  pct      = (Double)  row[4];
                double  divAmt   = (Double)  row[5];
                double  postAmt  = (Double)  row[6];
                long    warrNo   = (Long)    row[7];
                long    txnNo    = (Long)    row[8];
                String  txnDate  = nvlStr(row[9]);
                boolean posted   = txnNo != 0;

                tbl.addCell(tblCell(String.valueOf(sr),                         cellFont,  bg, Element.ALIGN_CENTER));
                tbl.addCell(tblCell(memCode,                                    cellFont,  bg, Element.ALIGN_LEFT));
                tbl.addCell(tblCell(payAc,                                      cellFontB, bg, Element.ALIGN_LEFT));
                tbl.addCell(tblCell(crAc.isEmpty() || "0".equals(crAc) ? "-" : crAc, cellFont, bg, Element.ALIGN_LEFT));
                tbl.addCell(tblCell(String.format("%,.2f", bal),                cellFont,  bg, Element.ALIGN_RIGHT));
                tbl.addCell(tblCell(pct + "%",                                  cellFont,  bg, Element.ALIGN_RIGHT));
                tbl.addCell(tblCell(String.format("%,.2f", divAmt),             cellFont,  bg, Element.ALIGN_RIGHT));
                tbl.addCell(tblCell(String.format("%,.2f", postAmt),            cellFontB, bg, Element.ALIGN_RIGHT));
                tbl.addCell(tblCell(String.valueOf(warrNo),                     cellFont,  bg, Element.ALIGN_CENTER));

                // Status badge cell
                PdfPCell statusCell = new PdfPCell(new Phrase(posted ? "Posted" : "Pending",
                    FontFactory.getFont(FontFactory.HELVETICA_BOLD, 6.5f,
                        posted ? new Color(0x0F, 0x6E, 0x56) : new Color(0x85, 0x4F, 0x0B))));
                statusCell.setBackgroundColor(posted ? GREEN_BG : ORANGE_BG);
                statusCell.setBorderColor(posted ? GREEN_BD : ORANGE);
                statusCell.setBorderWidth(0.5f);
                statusCell.setPadding(3);
                statusCell.setHorizontalAlignment(Element.ALIGN_CENTER);
                statusCell.setVerticalAlignment(Element.ALIGN_MIDDLE);
                tbl.addCell(statusCell);

                tbl.addCell(tblCell(txnDate == null || txnDate.isEmpty() ? "-" : txnDate,
                                    cellFont, bg, Element.ALIGN_CENTER));
            }

            // ── FOOTER TOTAL ROW ──
            PdfPCell totLabel = new PdfPCell(new Phrase("Total Dividend to Post :", footTotFont));
            totLabel.setColspan(7);
            totLabel.setBackgroundColor(NAVY);
            totLabel.setBorder(Rectangle.NO_BORDER);
            totLabel.setPadding(5);
            totLabel.setHorizontalAlignment(Element.ALIGN_RIGHT);
            tbl.addCell(totLabel);

            PdfPCell totVal = new PdfPCell(new Phrase("\u20B9 " + String.format("%,.2f", grandTotal), footTotFont));
            totVal.setBackgroundColor(NAVY);
            totVal.setBorder(Rectangle.NO_BORDER);
            totVal.setPadding(5);
            totVal.setHorizontalAlignment(Element.ALIGN_RIGHT);
            tbl.addCell(totVal);

            PdfPCell totBlank = new PdfPCell(new Phrase(""));
            totBlank.setColspan(3);
            totBlank.setBackgroundColor(NAVY);
            totBlank.setBorder(Rectangle.NO_BORDER);
            totBlank.setPadding(5);
            tbl.addCell(totBlank);

            doc.add(tbl);
            doc.close();

        } catch (Exception e) {
            if (!res.isCommitted()) {
                res.reset();
                res.setContentType("application/json; charset=UTF-8");
                res.getWriter().print("{\"success\":false,\"message\":\"PDF error: " + jsonSafeErr(e) + "\"}");
            }
        } finally {
            closeQuietly(rs, ps, conn);
        }
    }

    // ── Helper: build a plain data cell ──
    private PdfPCell tblCell(String text, Font f, Color bg, int align) {
        PdfPCell c = new PdfPCell(new Phrase(text == null ? "" : text, f));
        c.setBackgroundColor(bg);
        c.setBorderColor(new Color(0xD8, 0xD8, 0xF0));
        c.setBorderWidth(0.4f);
        c.setPaddingTop(4);
        c.setPaddingBottom(4);
        c.setPaddingLeft(4);
        c.setPaddingRight(4);
        c.setHorizontalAlignment(align);
        c.setVerticalAlignment(Element.ALIGN_MIDDLE);
        return c;
    }

    // ── Helper: format YYYY-MM-DD → DD-MM-YYYY ──
    private String fmtDate(String d) {
        if (d == null || d.length() < 10) return d;
        try {
            String[] p = d.split("-");
            return p[2] + "-" + p[1] + "-" + p[0];
        } catch (Exception e) { return d; }
    }

    private String nvlStr(Object o) { return o == null ? "" : o.toString().trim(); }

    // ══════════════════════════════════════════
    // ACTION 5 — Posting Payable
    // Calls sp_dividend_pay stored procedure
    // ══════════════════════════════════════════
    private void postingPayable(HttpServletRequest req, PrintWriter pw,
                                String branchCode, String userId) {
        String productCode = nvl(req.getParameter("productCode"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        CallableStatement cs = null;
        try {
            conn = DBConnection.getConnection();
            // sp_dividend_pay(branch, working_date, div_bal_date, y_begin, y_end, mem_product, user_id)
            cs = conn.prepareCall("{call sp_dividend_pay(?,?,?,?,?,?,?)}");
            cs.setString(1, branchCode);
            cs.setDate(2, new java.sql.Date(new java.util.Date().getTime()));
            cs.setDate(3, java.sql.Date.valueOf(divBalDate));
            cs.setDate(4, java.sql.Date.valueOf(yearBegin));
            cs.setDate(5, java.sql.Date.valueOf(yearEnd));
            cs.setString(6, productCode);
            cs.setString(7, userId);
            cs.execute();
            pw.print("{\"success\":true,\"message\":\"Dividend posted successfully to all accounts!\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(null, cs, conn);
        }
    }

    // ══════════════════════════════════════════
    // ACTION 6 — Posting SB
    // Posts dividend to SB savings accounts
    // NOTE: Currently calls the same sp_dividend_pay procedure as postingPayable.
    // If a separate SB-specific procedure exists (e.g. sp_dividend_pay_sb),
    // replace the prepareCall string below with that procedure name.
    // ══════════════════════════════════════════
    private void postingSB(HttpServletRequest req, PrintWriter pw,
                           String branchCode, String userId) {
        String productCode = nvl(req.getParameter("productCode"));
        String yearBegin   = nvl(req.getParameter("yearBegin"));
        String yearEnd     = nvl(req.getParameter("yearEnd"));
        String divBalDate  = nvl(req.getParameter("divBalDate"));
        Connection conn    = null;
        CallableStatement cs = null;
        try {
            conn = DBConnection.getConnection();
            cs = conn.prepareCall("{call sp_dividend_pay(?,?,?,?,?,?,?)}");
            cs.setString(1, branchCode);
            cs.setDate(2, new java.sql.Date(new java.util.Date().getTime()));
            cs.setDate(3, java.sql.Date.valueOf(divBalDate));
            cs.setDate(4, java.sql.Date.valueOf(yearBegin));
            cs.setDate(5, java.sql.Date.valueOf(yearEnd));
            cs.setString(6, productCode);
            cs.setString(7, userId);
            cs.execute();
            pw.print("{\"success\":true,\"message\":\"Dividend posted to SB accounts successfully!\"}");
        } catch (Exception e) {
            pw.print("{\"success\":false,\"message\":\"" + jsonSafeErr(e) + "\"}");
        } finally {
            closeQuietly(null, cs, conn);
        }
    }

    // ── Helper: close DB resources ──
    private void closeQuietly(ResultSet rs, Statement st, Connection conn) {
        try { if (rs   != null) rs.close();  } catch (Exception ignored) {}
        try { if (st   != null) st.close();  } catch (Exception ignored) {}
        try { if (conn != null) conn.close(); } catch (Exception ignored) {}
    }
}