
// ===============================
// COMMON LOOKUP JS (REUSABLE)
// ===============================

// 🔹 CONTEXT PATH (must be set in JSP)
if (typeof contextPath === "undefined") {
    var contextPath = "";
}

// ===============================
// 🔹 OPEN LOOKUP (branch/product/account)
// ===============================
function openLookup(type, extraParams) {

    let url = contextPath + "/CommonLookupServlet?type=" + type;

    if (extraParams) {
        url += "&" + extraParams;
    }

    fetch(url)
        .then(res => res.text())
        .then(html => {
            document.getElementById("lookupTable").innerHTML = html;
            document.getElementById("lookupModal").style.display = "flex";
        })
        .catch(err => console.error("Lookup Error:", err));
}

// ===============================
// 🔹 CLOSE LOOKUP
// ===============================
function closeLookup() {
    document.getElementById("lookupModal").style.display = "none";
}

// ===============================
// 🔹 SELECT BRANCH (WITH DESCRIPTION)
// ===============================
function selectBranch(code, name) {

    let codeField = document.getElementById("branch_code");
    if (codeField) codeField.value = code;

    let nameField = document.getElementById("branchName");
    if (nameField) nameField.value = name;

    closeLookup();
}

// ===============================
// 🔹 SELECT PRODUCT (WITH DESCRIPTION)  ✅ UPDATED
// ===============================
function selectProduct(code, name, type) {

    let field = document.getElementById("product_code");
    if (field) field.value = code;

    let nameField = document.getElementById("productName");
    if (nameField) nameField.value = name;

    closeLookup();
}

// ===============================
// 🔹 SELECT ACCOUNT (OPTIONAL)
// ===============================
function selectAccount(code, name) {

    let field = document.getElementById("account_code");
    if (field) field.value = code;

    let nameField = document.getElementById("account_name");
    if (nameField) nameField.value = name;

    closeLookup();
}

// ===============================
// 🔹 AUTO FETCH BRANCH NAME
// ===============================
function initBranchAutoFetch() {

    let field = document.getElementById("branch_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code || code.trim() === "") return;

        fetch(contextPath + "/CommonLookupServlet?type=branch&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {

                let desc = document.getElementById("branchName");
                if (desc) desc.value = name || "Not Found";

            })
            .catch(err => console.error("Branch Fetch Error:", err));
    });
}

// ===============================
// 🔹 AUTO FETCH PRODUCT NAME  ✅ NEW
// ===============================
function initProductAutoFetch() {

    let field = document.getElementById("product_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code || code.trim() === "") return;

        fetch(contextPath + "/CommonLookupServlet?type=product&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {

                let desc = document.getElementById("productName");
                if (desc) desc.value = name || "Not Found";

            })
            .catch(err => console.error("Product Fetch Error:", err));
    });
}

// ===============================
// 🔹 AUTO INIT
// ===============================
window.addEventListener("DOMContentLoaded", function () {
    initBranchAutoFetch();
    initProductAutoFetch();  // ✅ NEW
});

