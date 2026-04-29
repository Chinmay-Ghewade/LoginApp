// ===============================
// COMMON LOOKUP JS (REUSABLE)
// ===============================

// 🔹 CONTEXT PATH
if (typeof contextPath === "undefined") {
    var contextPath = "";
}

// ===============================
// 🔹 OPEN LOOKUP
// ===============================
let activeInput = null;

function openLookup(type, extraParams) {

    let btn = event ? event.target : document.activeElement;

    let box = btn.closest(".input-box");
    activeInput = box ? box.querySelector("input") : null;

    let url = contextPath + "/CommonLookupServlet?type=" + type;

    // 🔥 Auto-pass branch for account lookup
    if (type === "account") {
        let branchField = document.getElementById("branch_code");
        let branch = branchField ? branchField.value : "";

        if (!branch) {
            alert("Please select branch first");
            return;
        }

        url += "&branchCode=" + encodeURIComponent(branch);
    }

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
// 🔹 SELECT BRANCH
// ===============================
function selectBranch(code, name) {

    if (activeInput) {
        activeInput.value = code;
    } else {
        let codeField = document.getElementById("branch_code");
        if (codeField) codeField.value = code;
    }

    let nameField = document.getElementById("branchName");
    if (nameField) nameField.value = name;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH BRANCH NAME
// ===============================
function initBranchAutoFetch() {

    let field = document.getElementById("branch_code");

    if (!field || field.readOnly) return;

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
// 🔹 PAGE LOAD
// ===============================
function loadBranchNameOnPageLoad() {

    let branchField = document.getElementById("branch_code");
    let nameField = document.getElementById("branchName");

    if (!branchField || !nameField) return;

    let code = branchField.value;

    if (!code || code.trim() === "") return;

    fetch(contextPath + "/CommonLookupServlet?type=branch&action=getName&code=" + encodeURIComponent(code))
        .then(res => res.text())
        .then(name => {
            nameField.value = name || "Not Found";
        })
        .catch(err => console.error("Branch Load Error:", err));
}

// ===============================
// 🔹 SELECT PRODUCT
// ===============================
function selectProduct(code, name, type) {

    if (activeInput) {
        activeInput.value = code;
    } else {
        let field = document.getElementById("product_code");
        if (field) field.value = code;
    }

    let nameField = document.getElementById("productName");
    if (nameField) nameField.value = name;

    let typeField = document.getElementById("account_type");
    if (typeField) typeField.value = type;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH PRODUCT NAME
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
// 🔹 SELECT ACCOUNT
// ===============================
function selectAccount(code, name) {

    let field = document.getElementById("account_code");
    if (field) field.value = code;

    let nameField = document.getElementById("account_name");
    if (nameField) nameField.value = name;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH ACCOUNT NAME
// ===============================

function initAccountAutoFetch() {

    let field = document.getElementById("account_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code || code.trim() === "") return;

        fetch(contextPath + "/CommonLookupServlet?type=account&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let nameField = document.getElementById("account_name");
                if (nameField) nameField.value = name || "Not Found";
            })
            .catch(err => console.error("Account Fetch Error:", err));
    });
}

// ===============================
// 🔹 SELECT AREA
// ===============================

function selectArea(code, name) {

    if (activeInput) {
        activeInput.value = code;
    } else {
        let field = document.getElementById("area_code");
        if (field) field.value = code;
    }

    let nameField = document.getElementById("areaName");
    if (nameField) nameField.value = name;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH AREA NAME
// ===============================

function initAreaAutoFetch() {

    let field = document.getElementById("area_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code) return;

        fetch(contextPath + "/CommonLookupServlet?type=area&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let desc = document.getElementById("areaName");
                if (desc) desc.value = name || "Not Found";
            });
    });
}
// ===============================
// 🔹 SELECT INSTALLMENT
// ===============================

function selectInstallment(code, name) {

    // 🔥 FORCE SET (ignore activeInput issue completely)
    let codeField = document.getElementById("installment_code");
    if (codeField) {
        codeField.value = code;
    }

    let nameField = document.getElementById("installmentName");
    if (nameField) {
        nameField.value = name;
    }

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH INSTALLMENT NAME
// ===============================

function initInstallmentAutoFetch() {

    let field = document.getElementById("installment_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code) return;

        fetch(contextPath + "/CommonLookupServlet?type=installment&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let desc = document.getElementById("installmentName");
                if (desc) desc.value = name || "Not Found";
            });
    });
}

// ===============================
// 🔥 NEW: LOAD GL BY ACCOUNT TYPE
// ===============================
function loadGL(accountType) {

    let url = window.location.origin + contextPath +
        "/CommonLookupServlet?type=glByAccountType&accountType=" +
        encodeURIComponent(accountType);

    console.log("URL:", url); // DEBUG

    fetch(url)
        .then(res => res.text())
        .then(html => {
            console.log("GL HTML:", html); // DEBUG
            document.getElementById("lookupTable").innerHTML = html;
        })
        .catch(err => console.error("GL Load Error:", err));
}

// ===============================
// 🔥 NEW: SELECT GL ACCOUNT
// ===============================
function selectGL(glCode, desc) {

    let field = document.getElementById("product_code");
    if (field) field.value = glCode;

    let nameField = document.getElementById("productName");
    if (nameField) nameField.value = desc;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH GL ACCOUNT NAME
// ===============================

function initGLAutoFetch() {

    let field = document.getElementById("product_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code || code.trim() === "") return;

        fetch(contextPath + "/CommonLookupServlet?type=gl&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let desc = document.getElementById("productName");
                if (desc) desc.value = name || "Not Found";
            })
            .catch(err => console.error("GL Fetch Error:", err));
    });
}
// ===============================
// 🔥 ACCOUNT TYPE
// ===============================

function selectAccountType(code, name) {

    let field = document.getElementById("account_type");
    if (field) field.value = code;

    let nameField = document.getElementById("accountTypeName");
    if (nameField) nameField.value = name;

    closeLookup();
}

// ===============================
// 🔥 CUSTOMER
// ===============================

function selectCustomer(id, name) {

    let field = document.getElementById("customer_id");
    if (field) field.value = id;

    let nameField = document.getElementById("customerName");
    if (nameField) nameField.value = name;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH CUSTOMER NAME
// ===============================
function initCustomerAutoFetch() {

    let field = document.getElementById("customer_id");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code) return;

        fetch(contextPath + "/CommonLookupServlet?type=customer&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let desc = document.getElementById("customerName");
                if (desc) desc.value = name || "Not Found";
            });
    });
}

// ===============================
// 🔥 CITY
// ===============================
function selectCity(code, name) {

    let field = document.getElementById("city_code");
    if (field) field.value = code;

    let nameField = document.getElementById("cityName");
    if (nameField) nameField.value = name;

    closeLookup();
}
// ===============================
// 🔹 AUTO FETCH CITY NAME
// ===============================
function initCityAutoFetch() {

    let field = document.getElementById("city_code");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code) return;

        fetch(contextPath + "/CommonLookupServlet?type=city&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let desc = document.getElementById("cityName");
                if (desc) desc.value = name || "Not Found";
            });
    });
}

// ===============================
// 🔹 SELECT MEMBERTYPE
// ===============================
function selectMemberType(code, name) {

    // ✅ FORCE SET (like installment)
    let codeField = document.getElementById("member_type");
    if (codeField) {
        codeField.value = code;
    }

    let nameField = document.getElementById("memberTypeName");
    if (nameField) {
        nameField.value = name;
    }

    // ✅ CLEAR ACTIVE INPUT (important)
    activeInput = null;

    closeLookup();
}

// ===============================
// 🔹 AUTO FETCH MEMBER TYPE NAME
// ===============================
function initMemberTypeAutoFetch() {

    let field = document.getElementById("member_type");

    if (!field) return;

    field.addEventListener("blur", function () {

        let code = this.value;

        if (!code || code.trim() === "") return;

        fetch(contextPath + "/CommonLookupServlet?type=memberType&action=getName&code=" + encodeURIComponent(code))
            .then(res => res.text())
            .then(name => {
                let desc = document.getElementById("memberTypeName");
                if (desc) desc.value = name || "Not Found";
            })
            .catch(err => console.error("MemberType Fetch Error:", err));
    });
}

// ===============================
// 🔹 AUTO INIT
// ===============================
window.addEventListener("DOMContentLoaded", function () {
    initBranchAutoFetch();
    initProductAutoFetch();
    loadBranchNameOnPageLoad();
	initAccountAutoFetch();   
	initGLAutoFetch(); 
	initAreaAutoFetch();
	initInstallmentAutoFetch();   
	initCustomerAutoFetch();
	initCityAutoFetch();
	initMemberTypeAutoFetch();// ✅ ADD THIS

});