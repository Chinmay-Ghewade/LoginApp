/**
 * AUTO-BREADCRUMB SYSTEM
 * Most pages work automatically - only add exceptions below
 */

// ============================================
// ONLY ADD PAGES WITH CUSTOM NAMES HERE
// ============================================
const PAGE_EXCEPTIONS = {
		// View Details pages
	    'Dashboard/viewCustomer.jsp': 'View Details',
	    'View/viewAccount.jsp': 'View Details',
	    'authViewCustomers.jsp': 'View Details',
	    
	    // Special formatting
	    'Dashboard/aTypeMember.jsp': 'A Type Member',
	    'Dashboard/bTypeMember.jsp': 'B Type Member',
	    'Dashboard/otherMember.jsp': 'OTHER',
	    
	    // Loan pages
	    'Dashboard/loadOverdue.jsp': 'Loan Overdue',
	    'Dashboard/loanNPA.jsp': 'Loan NPA',
	    'Dashboard/loanRegular.jsp': 'Loan Regular',
	    'Dashboard/personalLoan.jsp': 'Personal Loan',
	    'Dashboard/securedLoan.jsp': 'Secured Loan',
	    'Dashboard/unsecuredLoan.jsp': 'Unsecured Loan',
	    'Dashboard/totalLoan.jsp': 'Total Loan',
		
		'Transactions/transactions.jsp': 'Transactions',
		'View/totalAccounts.jsp': 'Total Accounts',
		'View/allCustomers.jsp': 'Customers',
		
		// Authorization pages
		'authorizationPending.jsp': 'Authorization',
		'authorizationPendingCustomers.jsp': 'Customer List',
		'authorizationPendingApplications.jsp': 'Application List',
		'authViewCustomers.jsp': 'View Details',
		'authViewApplication.jsp': 'View Details',
		    
		// Other pages
		'addCustomer.jsp': 'Add Customer',
		'newApplication.jsp': 'Open Account',
		
		// Reports page
		'Reports/reports.jsp': 'Reports',
		
		// Master page
		'Master/masters.jsp': 'Master',
		'Master/editRow.jsp': 'Edit Record',
		
		// User Profile page
		'userProfile.jsp': 'User Profile',
		
		
		// ── Locker pages ──────────────────────────────
		'Lockers/locker.jsp':            'Lockers',
		'Lockers/lockerIssues.jsp':      'Locker Issues',
		'Lockers/lockerAttendance.jsp':  'Locker Attendance',
		'Lockers/lockerSurrender.jsp':   'Locker Surrender',
		'Lockers/lockerTransaction.jsp': 'Locker Transaction',
		'Lockers/lockerNominee.jsp':     'Locker Nominee',
		'Lockers/lockerJointHolder.jsp': 'Locker Joint Holder',
		
		
		// ── Casher pages ──────────────────────────────
		'Cashers/cashInOut.jsp'  			: 'Cash IN & OUT',
		'Cashers/combineDenomination.jsp'  	: 'Combine Denimination',
		'Cashers/denominationReport.jsp'  	: 'Denomination Master',
		'Cashers/denominationView.jsp'  	: 'Denomination View',
		'Cashers/userDenominationMaster.jsp': 'User Denomination Master',

	
	//Transactions
	
	
	// View
};

// Cache for generated breadcrumb strings
const _breadcrumbCache = new Map();

// Helper to build cache key
function _cacheKey(pagePath, returnPage) {
    return pagePath + '|' + (returnPage || '');
}

// AUTO-GENERATE TITLE FROM FILENAME
function autoGenerateTitle(filename) {
    return filename
        .replace(/([A-Z])/g, ' $1')
        .replace(/^./, str => str.toUpperCase())
        .trim();
}

// BUILD BREADCRUMB PATH (memoized)
function buildBreadcrumbPath(pagePath, returnPage = null) {
    const key = _cacheKey(pagePath, returnPage);
    if (_breadcrumbCache.has(key)) {
        return _breadcrumbCache.get(key);
    }

    // Handle dynamic parent (for View Details pages)
    let result;
    if (returnPage) {
        let parentBreadcrumb = buildBreadcrumbPath(returnPage);
        let currentTitle = PAGE_EXCEPTIONS[pagePath] || getPageTitle(pagePath);
        result = parentBreadcrumb + ' > ' + currentTitle;
        _breadcrumbCache.set(key, result);
        return result;
    }

    // Normal case: build from URL
    let parts = pagePath.replace('.jsp', '').split('/');

    // If folder name matches filename, only show once
    if (parts.length === 2 && parts[0].toLowerCase() === parts[1].toLowerCase()) {
        let fullPath = pagePath;
        result = PAGE_EXCEPTIONS[fullPath] || autoGenerateTitle(parts[0]);
        _breadcrumbCache.set(key, result);
        return result;
    }

    result = parts.map((part, index) => {
        let fullPath = parts.slice(0, index + 1).join('/') + '.jsp';
        return PAGE_EXCEPTIONS[fullPath] || autoGenerateTitle(part);
    }).join(' > ');

    _breadcrumbCache.set(key, result);
    return result;
}

// GET PAGE TITLE (unchanged)
function getPageTitle(pagePath) {
    if (PAGE_EXCEPTIONS[pagePath]) {
        return PAGE_EXCEPTIONS[pagePath];
    }
    let filename = pagePath.replace('.jsp', '').split('/').pop();
    return autoGenerateTitle(filename);
}

// Expose globally
window.buildBreadcrumbPath = buildBreadcrumbPath;
window.getPageTitle = getPageTitle;