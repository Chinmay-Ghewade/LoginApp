// ============================================================
// SHARED DROPDOWN LOADER FOR ALL ACCOUNT FORMS
// Loads all dropdowns via one AJAX call to AccountFormDataLoader
// ============================================================

(function () {
    'use strict';

    // ── Configuration: maps data key → array of select element IDs ──
    // Multiple IDs per key because nominee/joint/guarantor repeat the same data
    var DD_CONFIG = {
        salutation: [
            'dd-nomineeSalutation',
            'dd-jointSalutation',
            'dd-coBorrowerSalutation',
            'dd-guarantorSalutation'
        ],
        relation: [
            'dd-nomineeRelation'
        ],
        country: [
            'dd-nomineeCountry',
            'dd-jointCountry',
            'dd-coBorrowerCountry',
            'dd-guarantorCountry',
            'dd-salaryCountry'
        ],
        state: [
            'dd-nomineeState',
            'dd-jointState',
            'dd-coBorrowerState',
            'dd-guarantorState',
            'dd-salaryState'
        ],
        city: [
            'dd-nomineeCity',
            'dd-jointCity',
            'dd-coBorrowerCity',
            'dd-guarantorCity',
            'dd-salaryCity',
            'dd-nonmotorCity'
        ],
        accountOperationCapacity: [
            'dd-accountOperationCapacity'
        ],
        minBalance: [
            'dd-minBalance'
        ],
		securityType: [
		    'dd-lbSecurityType',
		    'dd-depositSecurityType',
		    'dd-gsSecurityType',
		    'dd-sharesHolderSecurityType',
		    'dd-plantSecurityType',
		    'dd-stockSecurityType',
		    'dd-salarySecurityType',
		    'dd-insSecurityType',
		    'dd-motorSecurityType',
		    'dd-officeSecurityType',
			'dd-marketSharesSecurityType'
		]
    };

    // ── Fill one <select> from {v, l} items ──
    function fillSelect(selectEl, items, addBlank) {
        selectEl.innerHTML = '';

        if (addBlank !== false) {
            var blank = document.createElement('option');
            blank.value = '';
            blank.textContent = '-- Select --';
            selectEl.appendChild(blank);
        }

        items.forEach(function (item) {
            var opt = document.createElement('option');
            opt.value = item.v;
            opt.textContent = item.l !== item.v && item.l
                ? item.v + ' — ' + item.l
                : item.v;
            // For city/state/relation show label only (not code)
            if (['relation','city'].indexOf(getKeyForSelect(selectEl.id)) !== -1) {
                opt.textContent = item.l || item.v;
            }
            selectEl.appendChild(opt);
        });

        selectEl.classList.remove('dd-loading');
    }

    function getKeyForSelect(id) {
        for (var key in DD_CONFIG) {
            if (DD_CONFIG[key].indexOf(id) !== -1) return key;
        }
        return '';
    }

    // ── Clone a filled select into another select ──
    function cloneSelectOptions(sourceEl, targetEl) {
        targetEl.innerHTML = sourceEl.innerHTML;
        targetEl.classList.remove('dd-loading');
    }

    // ── Main loader ──
    window.loadAccountFormDropdowns = function (contextPath) {
        var url = (contextPath || '') + '/loaders/AccountFormDataLoader';

        fetch(url)
            .then(function (res) {
                if (!res.ok) throw new Error('HTTP ' + res.status);
                return res.json();
            })
            .then(function (data) {
                if (data._error) {
                    console.warn('Dropdown warning:', data._error);
                }

                // For each key, fill the first matching select,
                // then clone to the rest (faster than re-querying DB)
                Object.keys(DD_CONFIG).forEach(function (key) {
                    var ids = DD_CONFIG[key];
                    var items = data[key];
                    if (!Array.isArray(items)) return;

                    var firstFilled = null;

                    ids.forEach(function (id) {
                        var el = document.getElementById(id);
                        if (!el) return;

                        if (!firstFilled) {
                            fillSelect(el, items);
                            firstFilled = el;
                        } else {
                            cloneSelectOptions(firstFilled, el);
                        }
                    });
                });

                console.log('✅ Account form dropdowns loaded');

                // Fire a custom event so individual pages can react
                document.dispatchEvent(new CustomEvent('formDropdownsLoaded'));
            })
            .catch(function (err) {
                console.error('❌ Dropdown load error:', err);
            });
    };

})();