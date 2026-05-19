<%--
    loadingOverlay.jsp
    ─────────────────────────────────────────────────────────────────────────
    Reusable full-screen loading overlay component.

    HOW TO INCLUDE:
        <%@ include file="/loadingOverlay.jsp" %>
        OR (dynamic include):
        <jsp:include page="/loadingOverlay.jsp" />

    Place the include INSIDE <body>, before the closing </body> tag.

    USAGE FROM JAVASCRIPT:
    ──────────────────────
    // Show with default message:
        LoadingOverlay.show();

    // Show with custom message and sub-text:
        LoadingOverlay.show('Loading Loan Form...', 'Fetching product configuration');

    // Show using named preset (same presets as newApplication.jsp):
        LoadingOverlay.showForAccountType('TD', '102');   // accType, prodCode

    // Hide:
        LoadingOverlay.hide();

    PRESETS (account type → label):
        SB → Saving Account
        CA → Current Account
        TD → Term Deposit
        CC → Cash Credit Loan
        TL → Term Loan
        PG → Pigmy
        SH → Shares
        FA → Fixed Asset

    CUSTOMISATION (optional JSP params when using jsp:include):
        spinnerColor  – CSS color of the spinner ring  (default: #373279)
        bgAlpha       – backdrop opacity 0-1           (default: 0.85)
--%>

<%
    String _spinnerColor = request.getParameter("spinnerColor");
    if (_spinnerColor == null || _spinnerColor.trim().isEmpty()) _spinnerColor = "#373279";

    String _bgAlphaStr = request.getParameter("bgAlpha");
    double _bgAlpha = 0.85;
    try { if (_bgAlphaStr != null) _bgAlpha = Double.parseDouble(_bgAlphaStr); } catch (Exception _ignored) {}
%>

<!-- ═══════════════════════ LOADING OVERLAY ═══════════════════════ -->
<style>
#globalPageLoader {
    display: none;
    position: fixed;
    top: 0; left: 0;
    width: 100%; height: 100%;
    background: rgba(232, 228, 252, <%= _bgAlpha %>);
    z-index: 99990;
    flex-direction: column;
    align-items: center;
    justify-content: center;
}

#globalPageLoader .loader-card {
    background: #ffffff;
    border-radius: 16px;
    padding: 42px 64px;
    box-shadow: 0 10px 40px rgba(55, 50, 121, 0.18);
    text-align: center;
    min-width: 280px;
    animation: loaderFadeIn 0.25s ease;
}

@keyframes loaderFadeIn {
    from { opacity: 0; transform: scale(0.93); }
    to   { opacity: 1; transform: scale(1);    }
}

#globalPageLoader .loader-spinner {
    width: 54px;
    height: 54px;
    border: 5px solid #e8e4fc;
    border-top-color: <%= _spinnerColor %>;
    border-radius: 50%;
    animation: loaderSpin 0.75s linear infinite;
    margin: 0 auto 22px;
}

@keyframes loaderSpin {
    to { transform: rotate(360deg); }
}

#globalPageLoader .loader-title {
    font-size: 16px;
    font-weight: 700;
    color: <%= _spinnerColor %>;
    margin-bottom: 7px;
    font-family: Arial, sans-serif;
    line-height: 1.4;
}

#globalPageLoader .loader-sub {
    font-size: 13px;
    color: #888;
    font-family: Arial, sans-serif;
}

/* Progress dots animation on sub-text */
#globalPageLoader .loader-dots::after {
    content: '';
    animation: loaderDots 1.4s steps(4, end) infinite;
}
@keyframes loaderDots {
    0%   { content: '';    }
    25%  { content: '.';   }
    50%  { content: '..';  }
    75%  { content: '...'; }
    100% { content: '';    }
}
</style>

<div id="globalPageLoader">
    <div class="loader-card">
        <div class="loader-spinner"></div>
        <div id="globalLoaderTitle" class="loader-title">Loading<span class="loader-dots"></span></div>
        <div id="globalLoaderSub"   class="loader-sub">Please wait</div>
    </div>
</div>

<script>
/* ──────────────────────────────────────────────────────────
   LoadingOverlay  –  global namespace, safe to call from
   any page that includes this fragment.
   ────────────────────────────────────────────────────────── */
var LoadingOverlay = (function () {

    var _TYPE_LABELS = {
        "SB": "Saving Account",
        "CA": "Current Account",
        "TD": "Term Deposit",
        "CC": "Cash Credit Loan",
        "TL": "Term Loan",
        "PG": "Pigmy",
        "SH": "Shares",
        "FA": "Fixed Asset"
    };

    function _el(id) { return document.getElementById(id); }

    /**
     * show(title, subText)
     * Both params are optional.
     */
    function show(title, subText) {
        var overlay = _el('globalPageLoader');
        if (!overlay) return;

        _el('globalLoaderTitle').innerHTML =
            (title  || 'Loading') + '<span class="loader-dots"></span>';
        _el('globalLoaderSub').textContent =
            (subText || 'Please wait');

        overlay.style.display = 'flex';
    }

    /**
     * showForAccountType(accType, prodCode)
     * Mirrors the logic in newApplication.jsp's showLoader().
     */
    function showForAccountType(accType, prodCode) {
        var label = _TYPE_LABELS[accType] || accType;
        show(
            'Loading ' + label + ' Form\u2026',
            prodCode ? ('Product Code: ' + prodCode + ' \u2014 fetching configuration') : 'Fetching configuration'
        );
    }

    /**
     * hide()
     */
    function hide() {
        var overlay = _el('globalPageLoader');
        if (overlay) overlay.style.display = 'none';
    }

    /**
     * autoHideOnIframeLoad(iframeId)
     * Attaches an onload listener to the given iframe so the overlay
     * is hidden automatically once the iframe finishes loading.
     */
    function autoHideOnIframeLoad(iframeId) {
        var iframe = _el(iframeId);
        if (!iframe) return;
        iframe.addEventListener('load', function () { hide(); });
    }

    /* public API */
    return {
        show               : show,
        showForAccountType : showForAccountType,
        hide               : hide,
        autoHideOnIframeLoad: autoHideOnIframeLoad
    };
}());
</script>
<!-- ════════════════════ END LOADING OVERLAY ════════════════════ -->
