<%--
    popupMessages.jsp
    ─────────────────────────────────────────────────────────────────────────
    Reusable modal popup component for success, error, warning and info
    messages.  Replaces all Toastify calls for application-level feedback
    (form save, form error, etc.).

    HOW TO INCLUDE:
        <%@ include file="/popupMessages.jsp" %>
        OR (dynamic include):
        <jsp:include page="/popupMessages.jsp" />

    Place the include INSIDE <body>, before the closing </body> tag.
    Include it ONCE per page — it registers a single modal and a global
    `PopupMsg` object.

    ─────────────────────────────────────────────────────────────────────────
    JAVASCRIPT API
    ─────────────────────────────────────────────────────────────────────────

    PopupMsg.success(title, message, onOk)
        Shows a green ✓ success modal.
        onOk  – optional callback when the user clicks OK.

    PopupMsg.error(title, message, onOk)
        Shows a red ✕ error modal.

    PopupMsg.warning(title, message, onOk)
        Shows an orange ⚠ warning modal.

    PopupMsg.info(title, message, onOk)
        Shows a blue ℹ info modal.

    PopupMsg.close()
        Programmatically close the modal.

    PopupMsg.fromUrlParams(successTitle, errorTitle)
        Reads  ?status=success|error  &applicationNumber=...  &message=...
        from the current URL and auto-shows the correct popup, then
        cleans the URL.  Call this in DOMContentLoaded.

        successTitle – optional, default "Application Saved Successfully"
        errorTitle   – optional, default "Failed to Save Application"

    PopupMsg.customerCreated(customerId)
        Special preset popup shown after a customer is created.
        Mirrors the showCustomerSuccessModal() from addCustomer.js.

    ─────────────────────────────────────────────────────────────────────────
    EXAMPLES
    ─────────────────────────────────────────────────────────────────────────

    // Show success after saving a form:
    PopupMsg.success(
        'Application Saved',
        'Application Number: 00010000000042'
    );

    // Show error:
    PopupMsg.error('Save Failed', 'Customer ID is required.');

    // Auto-detect from URL (put in DOMContentLoaded):
    document.addEventListener('DOMContentLoaded', function () {
        PopupMsg.fromUrlParams('Term Deposit Saved', 'Term Deposit Error');
    });

    // Customer created preset:
    PopupMsg.customerCreated('00010000001');
--%>

<!-- ═══════════════════════ POPUP MESSAGES ═══════════════════════ -->
<style>
/* ── Backdrop ── */
#globalPopupOverlay {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(0, 0, 0, 0.55);
    z-index: 99995;
    align-items: center;
    justify-content: center;
    animation: popupFadeIn 0.2s ease;
}
@keyframes popupFadeIn {
    from { opacity: 0; }
    to   { opacity: 1; }
}

/* ── Card ── */
#globalPopupCard {
    background: #ffffff;
    border-radius: 12px;
    width: 440px;
    max-width: 92vw;
    padding: 38px 40px 32px;
    box-shadow: 0 8px 40px rgba(0, 0, 0, 0.22);
    text-align: center;
    position: relative;
    animation: popupSlideUp 0.25s ease;
    font-family: Arial, sans-serif;
}
@keyframes popupSlideUp {
    from { transform: translateY(28px); opacity: 0; }
    to   { transform: translateY(0);    opacity: 1; }
}

/* ── Icon circle ── */
#globalPopupIconWrap {
    width: 68px;
    height: 68px;
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    margin: 0 auto 20px;
    font-size: 32px;
    font-weight: bold;
}

/* ── Title ── */
#globalPopupTitle {
    font-size: 19px;
    font-weight: 700;
    color: #222;
    margin-bottom: 12px;
    line-height: 1.35;
}

/* ── Body message ── */
#globalPopupMsg {
    font-size: 14px;
    color: #555;
    line-height: 1.65;
    margin-bottom: 28px;
    white-space: pre-line;   /* honour \n in messages */
    word-break: break-word;
}

/* ── OK button ── */
#globalPopupOkBtn {
    border: none;
    padding: 12px 52px;
    border-radius: 8px;
    font-size: 15px;
    font-weight: 700;
    cursor: pointer;
    transition: opacity 0.2s, transform 0.15s;
    color: #ffffff;
    letter-spacing: 0.3px;
}
#globalPopupOkBtn:hover  { opacity: 0.88; transform: scale(1.03); }
#globalPopupOkBtn:active { transform: scale(0.97); }

/* ── Close × (top-right) ── */
#globalPopupClose {
    position: absolute;
    top: 14px; right: 18px;
    font-size: 24px;
    color: #aaa;
    cursor: pointer;
    line-height: 1;
    transition: color 0.15s;
}
#globalPopupClose:hover { color: #555; }

/* ── Type-specific accent colours ── */
.popup-success #globalPopupIconWrap { background: #e6f9f0; color: #28a745; }
.popup-success #globalPopupOkBtn    { background: #28a745; }
.popup-success #globalPopupOkBtn:hover { background: #218838; opacity:1; }

.popup-error   #globalPopupIconWrap { background: #fde8e8; color: #e53935; }
.popup-error   #globalPopupOkBtn    { background: #e53935; }
.popup-error   #globalPopupOkBtn:hover { background: #c62828; opacity:1; }

.popup-warning #globalPopupIconWrap { background: #fff3e0; color: #f57c00; }
.popup-warning #globalPopupOkBtn    { background: #f57c00; }
.popup-warning #globalPopupOkBtn:hover { background: #e65100; opacity:1; }

.popup-info    #globalPopupIconWrap { background: #e3f2fd; color: #1976d2; }
.popup-info    #globalPopupOkBtn    { background: #1976d2; }
.popup-info    #globalPopupOkBtn:hover { background: #1565c0; opacity:1; }

/* ── Customer-created special variant ── */
.popup-customer #globalPopupIconWrap { background: #e6f9f0; color: #28a745; }
.popup-customer #globalPopupOkBtn    { background: #28a745; }
.popup-customer #globalPopupOkBtn:hover { background: #218838; opacity:1; }
.popup-customer #globalPopupCustomerId {
    font-size: 22px;
    font-weight: 700;
    color: #373279;
    background: #f0edff;
    border-radius: 8px;
    padding: 10px 22px;
    display: inline-block;
    margin: -6px 0 20px;
    letter-spacing: 1px;
}
</style>

<!-- The single modal element shared by all popup calls -->
<div id="globalPopupOverlay">
    <div id="globalPopupCard">
        <span id="globalPopupClose" onclick="PopupMsg.close()" title="Close">&times;</span>
        <div  id="globalPopupIconWrap"></div>
        <div  id="globalPopupTitle"></div>
        <div  id="globalPopupMsg"></div>
        <button id="globalPopupOkBtn" onclick="PopupMsg._okClicked()">OK</button>
    </div>
</div>

<script>
/* ──────────────────────────────────────────────────────────────
   PopupMsg  –  global namespace.
   ────────────────────────────────────────────────────────────── */
var PopupMsg = (function () {

    var _overlay  = null;
    var _card     = null;
    var _iconWrap = null;
    var _titleEl  = null;
    var _msgEl    = null;
    var _okBtn    = null;
    var _onOkCb   = null;

    /* Type config */
    var _TYPES = {
        success  : { cls: 'popup-success',  icon: '&#10003;' },   /* ✓ */
        error    : { cls: 'popup-error',    icon: '&#10005;' },   /* ✕ */
        warning  : { cls: 'popup-warning',  icon: '&#9888;'  },   /* ⚠ */
        info     : { cls: 'popup-info',     icon: '&#9432;'  },   /* ℹ */
        customer : { cls: 'popup-customer', icon: '&#10003;' }    /* ✓ */
    };

    function _init() {
        if (_overlay) return;
        _overlay  = document.getElementById('globalPopupOverlay');
        _card     = document.getElementById('globalPopupCard');
        _iconWrap = document.getElementById('globalPopupIconWrap');
        _titleEl  = document.getElementById('globalPopupTitle');
        _msgEl    = document.getElementById('globalPopupMsg');
        _okBtn    = document.getElementById('globalPopupOkBtn');

        /* Close on backdrop click */
        _overlay.addEventListener('click', function (e) {
            if (e.target === _overlay) _close();
        });
        /* Close on Escape */
        document.addEventListener('keydown', function (e) {
            if (e.key === 'Escape' && _overlay.style.display === 'flex') _close();
        });
    }

    function _show(type, title, message, onOk) {
        _init();
        var cfg = _TYPES[type] || _TYPES.info;

        /* Remove previous type classes */
        _card.className = cfg.cls;

        _iconWrap.innerHTML = cfg.icon;
        _titleEl.textContent = title   || '';
        _msgEl.textContent   = message || '';
        _onOkCb = onOk || null;

        _overlay.style.display = 'flex';
        _okBtn.focus();
    }

    function _close() {
        if (_overlay) _overlay.style.display = 'none';
    }

    function _okClicked() {
        _close();
        if (typeof _onOkCb === 'function') {
            try { _onOkCb(); } catch (e) { console.error('PopupMsg onOk error', e); }
        }
    }

    /* ── fromUrlParams ── */
    function _fromUrlParams(successTitle, errorTitle) {
        var params = new URLSearchParams(window.location.search);
        var status = params.get('status');
        var appNum = params.get('applicationNumber');
        var msg    = params.get('message');

        if (status === 'success' && appNum) {
            _show(
                'success',
                successTitle || 'Application Saved Successfully',
                'Application Number: ' + appNum
            );
            _cleanUrl();
        } else if (status === 'error') {
            _show(
                'error',
                errorTitle || 'Failed to Save Application',
                msg ? decodeURIComponent(msg) : 'An unexpected error occurred. Please try again.'
            );
            _cleanUrl();
        }
    }

    function _cleanUrl() {
        var clean = window.location.pathname +
            window.location.search
                .replace(/[?&](status|applicationNumber|message)=[^&]*/g, '')
                .replace(/^&/, '?')
                .replace(/\?$/, '');
        window.history.replaceState({}, document.title, clean || window.location.pathname);
    }

    /* ── customerCreated preset ── */
    function _customerCreated(customerId, onOk) {
        _init();
        _card.className = 'popup-customer';
        _iconWrap.innerHTML = '&#10003;';
        _titleEl.textContent = 'Customer Added Successfully!';

        /* Inject custom HTML: large Customer-ID badge */
        _msgEl.innerHTML =
            'The new customer record has been saved.\n\n' +
            'Customer ID\n' +
            '<span id="globalPopupCustomerId">' + customerId + '</span>';

        _onOkCb = onOk || null;
        _overlay.style.display = 'flex';

        /* Default onOk: reset the form if present */
        if (!onOk) {
            _onOkCb = function () {
                var form = document.querySelector('form');
                if (form) form.reset();
            };
        }

        _okBtn.focus();
    }

    /* ── fromUrlParams for customer page ── */
    function _fromCustomerUrlParams() {
        var params     = new URLSearchParams(window.location.search);
        var status     = params.get('status');
        var customerId = params.get('customerId');
        var msg        = params.get('message');

        if (status === 'success' && customerId) {
            _customerCreated(customerId);
            _cleanUrl();
        } else if (status === 'error') {
            _show(
                'error',
                'Failed to Add Customer',
                msg ? decodeURIComponent(msg) : 'An unexpected error occurred. Please try again.'
            );
            _cleanUrl();
        }
    }

    /* public API */
    return {
        success            : function (t, m, cb) { _show('success', t, m, cb); },
        error              : function (t, m, cb) { _show('error',   t, m, cb); },
        warning            : function (t, m, cb) { _show('warning', t, m, cb); },
        info               : function (t, m, cb) { _show('info',    t, m, cb); },
        close              : _close,
        _okClicked         : _okClicked,
        fromUrlParams      : _fromUrlParams,
        fromCustomerUrlParams: _fromCustomerUrlParams,
        customerCreated    : _customerCreated
    };
}());
</script>
<!-- ════════════════════ END POPUP MESSAGES ════════════════════ -->
