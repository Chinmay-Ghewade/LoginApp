// ============================================
// APPLICATION FORMS TABBED NAVIGATION WITH VALIDATION
// Auto-detects fieldsets and creates tabs dynamically
// ============================================

(function() {
    'use strict';

    let currentTab = 1;
    const completedTabs = new Set();
    const enabledTabs = new Set([1]); // Tab 1 starts enabled
    let TABS = [];

	// Initialize tabs on page load
	function initializeTabs() {
	    detectFieldsets();
	    
	    if (TABS.length <= 1) {
	        console.log('⚠️ Only one fieldset found, tab navigation not needed');
	        
	        // ✅ NEW: Ensure form buttons are visible when no tabs
	        const formButtons = document.querySelector('.form-buttons');
	        if (formButtons) {
	            formButtons.classList.add('show');
	            formButtons.style.display = 'flex';
	        }
	        return;
	    }

	    createTabNavigation();
	    wrapFieldsetsInTabContent();
	    hideOriginalButtons();
	    createNavigationButtons();
	    updateTabState();
	    
	    console.log('✅ Application tab navigation initialized with', TABS.length, 'tabs');
	}

    // Auto-detect fieldsets and create tab configuration
    function detectFieldsets() {
        const fieldsets = document.querySelectorAll('fieldset');
        
        fieldsets.forEach((fieldset, index) => {
            const legend = fieldset.querySelector('legend');
            const tabName = legend ? legend.textContent.trim() : `Step ${index + 1}`;
            
            TABS.push({
                id: index + 1,
                name: tabName,
                fieldsetIndex: index
            });
        });
    }

    // Create tab navigation HTML
    function createTabNavigation() {
        const nav = document.createElement('div');
        nav.className = 'app-tab-navigation';
        nav.innerHTML = `
            <ul class="app-tab-list" role="tablist">
                ${TABS.map(tab => `
                    <li class="app-tab-item">
                        <button class="app-tab-button ${tab.id === 1 ? 'active' : ''}" 
                                data-tab="${tab.id}" 
                                type="button"
                                role="tab"
                                aria-selected="${tab.id === 1}"
                                ${tab.id !== 1 ? 'disabled' : ''}>
                            <span class="app-tab-number">${tab.id}</span>
                            <span class="app-tab-label">${tab.name}</span>
                        </button>
                    </li>
                `).join('')}
            </ul>
            <div class="app-progress-bar-container">
                <div class="app-progress-bar" style="width: ${(1 / TABS.length) * 100}%"></div>
            </div>
        `;

        const form = document.querySelector('form');
        form.insertBefore(nav, form.firstChild);

        // Add click handlers
        document.querySelectorAll('.app-tab-button').forEach(btn => {
            btn.addEventListener('click', handleTabClick);
        });
    }

    // Wrap each fieldset in tab content div
    function wrapFieldsetsInTabContent() {
        const fieldsets = document.querySelectorAll('fieldset');
        
        fieldsets.forEach((fieldset, index) => {
            const wrapper = document.createElement('div');
            wrapper.className = `app-tab-content ${index === 0 ? 'active' : ''}`;
            wrapper.setAttribute('data-tab-content', index + 1);
            wrapper.setAttribute('role', 'tabpanel');
            
            fieldset.parentNode.insertBefore(wrapper, fieldset);
            wrapper.appendChild(fieldset);
        });
    }

    // Hide original submit/reset buttons
    function hideOriginalButtons() {
        const formButtons = document.querySelector('.form-buttons');
        if (formButtons) {
            formButtons.style.display = 'none';
        }
    }

    // Create Previous/Next navigation buttons
    function createNavigationButtons() {
        const navButtons = document.createElement('div');
        navButtons.className = 'app-tab-navigation-buttons';
        navButtons.innerHTML = `
            <button type="button" class="app-nav-button prev-btn" id="appPrevTabBtn" disabled>
                Previous
            </button>
            <span class="app-step-indicator">Step <span id="appCurrentStep">1</span> of ${TABS.length}</span>
            <button type="button" class="app-nav-button next-btn" id="appNextTabBtn">
                Next
            </button>
        `;

        // Insert before the last tab content
        const lastTabContent = document.querySelector(`[data-tab-content="${TABS.length}"]`);
        lastTabContent.parentNode.insertBefore(navButtons, lastTabContent.nextSibling);

        // Add event listeners
        document.getElementById('appPrevTabBtn').addEventListener('click', goToPreviousTab);
        document.getElementById('appNextTabBtn').addEventListener('click', goToNextTab);
    }

    // Handle tab button click
    function handleTabClick(e) {
        const btn = e.currentTarget;
        const targetTab = parseInt(btn.dataset.tab);

        if (btn.disabled || !enabledTabs.has(targetTab)) {
            return;
        }

        switchToTab(targetTab);
    }

    // Switch to specific tab
    function switchToTab(tabNumber) {
        // Hide all tab contents
        document.querySelectorAll('.app-tab-content').forEach(content => {
            content.classList.remove('active');
        });

        // Show target tab content
        const targetContent = document.querySelector(`[data-tab-content="${tabNumber}"]`);
        if (targetContent) {
            targetContent.classList.add('active');
            
            // Smooth scroll to top
            window.scrollTo({
                top: 0,
                behavior: 'smooth'
            });
        }

        // Update active state
        document.querySelectorAll('.app-tab-button').forEach(btn => {
            btn.classList.remove('active');
            btn.setAttribute('aria-selected', 'false');
        });

        const activeBtn = document.querySelector(`[data-tab="${tabNumber}"]`);
        if (activeBtn) {
            activeBtn.classList.add('active');
            activeBtn.setAttribute('aria-selected', 'true');
        }

        currentTab = tabNumber;
        updateTabState();
    }

    // Update tab state (buttons, progress, etc.)
    function updateTabState() {
        const prevBtn = document.getElementById('appPrevTabBtn');
        const nextBtn = document.getElementById('appNextTabBtn');
        const stepIndicator = document.getElementById('appCurrentStep');
        const formButtons = document.querySelector('.form-buttons');
        const progressBar = document.querySelector('.app-progress-bar');

        // Update step indicator
        if (stepIndicator) {
            stepIndicator.textContent = currentTab;
        }

        // Update progress bar
        if (progressBar) {
            const progress = (currentTab / TABS.length) * 100;
            progressBar.style.width = progress + '%';
        }

        // Enable/disable previous button
        if (prevBtn) {
            prevBtn.disabled = currentTab === 1;
        }

        // Update next button or show form buttons
        if (currentTab === TABS.length) {
            // Last tab - hide next button, show submit/reset
            if (nextBtn) nextBtn.style.display = 'none';
            if (formButtons) {
                formButtons.style.display = 'flex';
                formButtons.classList.add('show');
            }
        } else {
            // Not last tab - show next button, hide submit/reset
            if (nextBtn) nextBtn.style.display = 'flex';
            if (formButtons) {
                formButtons.style.display = 'none';
                formButtons.classList.remove('show');
            }
        }

        // Update tab button states
        document.querySelectorAll('.app-tab-button').forEach(btn => {
            const tabId = parseInt(btn.dataset.tab);
            
            if (enabledTabs.has(tabId)) {
                btn.disabled = false;
                btn.classList.add('enabled');
            }
            
            if (completedTabs.has(tabId)) {
                btn.classList.add('completed');
            }
        });
    }

    // Go to previous tab
    function goToPreviousTab() {
        if (currentTab > 1) {
            switchToTab(currentTab - 1);
        }
    }

    // Go to next tab with validation
    async function goToNextTab() {
        const isValid = await validateCurrentTab();
        
        if (isValid) {
            // Mark current tab as completed
            completedTabs.add(currentTab);
            
            // Enable next tab
            if (currentTab < TABS.length) {
                enabledTabs.add(currentTab + 1);
                switchToTab(currentTab + 1);
            }
        } else {
            // Validation failed - errors are already highlighted in the form
            console.log('Validation failed for tab', currentTab);
            
            // Scroll to first error field
            const firstError = document.querySelector('.app-field-error');
            if (firstError) {
                firstError.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        }
    }

    // Validate current tab
    async function validateCurrentTab() {
        const tabContent = document.querySelector(`[data-tab-content="${currentTab}"]`);
        if (!tabContent) return false;

        clearAllErrors(tabContent);

        let isValid = true;

        // Get all inputs in current tab
        const inputs = tabContent.querySelectorAll('input, select, textarea');

        for (const input of inputs) {
            // Skip disabled inputs
            if (input.disabled) continue;

            // Skip inputs that are not visible (hidden by conditional logic)
            if (!isElementVisible(input)) continue;

            // Check required fields
            if (input.hasAttribute('required') || input.closest('[required]')) {
                if (!validateField(input)) {
                    isValid = false;
                    markFieldAsError(input);
                }
            }

            // Special validation for specific fields
            if (input.name && input.value) {
                const fieldValidation = validateSpecialField(input);
                if (!fieldValidation.valid) {
                    isValid = false;
                    markFieldAsError(input, fieldValidation.message);
                }
            }
        }

        // Validate radio button groups
        const radioGroups = getRadioGroups(tabContent);
        for (const [name, radios] of radioGroups) {
            const firstRadio = radios[0];
            if (firstRadio.hasAttribute('required')) {
                const isChecked = radios.some(r => r.checked);
                if (!isChecked) {
                    isValid = false;
                    radios.forEach(r => markFieldAsError(r));
                }
            }
        }

        return isValid;
    }

    // Check if element is visible
    function isElementVisible(element) {
        if (!element) return false;
        
        const style = window.getComputedStyle(element);
        if (style.display === 'none' || style.visibility === 'hidden') return false;
        
        let parent = element.parentElement;
        while (parent) {
            const parentStyle = window.getComputedStyle(parent);
            if (parentStyle.display === 'none' || parentStyle.visibility === 'hidden') return false;
            parent = parent.parentElement;
        }
        
        return true;
    }

    // Validate individual field
    function validateField(field) {
        if (field.type === 'radio') {
            const name = field.name;
            const group = document.querySelectorAll(`input[name="${name}"]`);
            return Array.from(group).some(r => r.checked);
        }

        if (field.type === 'checkbox') {
            return field.checked;
        }

        if (field.tagName === 'SELECT') {
            return field.value !== '' && field.value !== null;
        }

        if (field.type === 'email') {
            const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
            return field.value.trim() !== '' && emailRegex.test(field.value);
        }

        return field.value.trim() !== '';
    }

    // Validate special fields with patterns
    function validateSpecialField(field) {
        const patterns = {
            introducerAccCode: { regex: /^[0-9]{14}$/, message: 'Introducer Account Code must be 14 digits' },
            zip: { regex: /^[0-9]{6}$/, message: 'ZIP must be 6 digits' },
            nomineeZip: { regex: /^[0-9]{6}$/, message: 'ZIP must be 6 digits' },
            jointZip: { regex: /^[0-9]{6}$/, message: 'ZIP must be 6 digits' },
            email: { regex: /^[^\s@]+@[^\s@]+\.[^\s@]+$/, message: 'Invalid email format' }
        };

        // Check for array field names (nominee, joint holder fields)
        const fieldBaseName = field.name.replace('[]', '');
        
        if (patterns[field.name] || patterns[fieldBaseName]) {
            const pattern = patterns[field.name] || patterns[fieldBaseName];
            if (!pattern.regex.test(field.value)) {
                return { valid: false, message: pattern.message };
            }
        }

        return { valid: true };
    }

    // Get radio button groups
    function getRadioGroups(container) {
        const groups = new Map();
        const radios = container.querySelectorAll('input[type="radio"]');
        
        radios.forEach(radio => {
            if (!radio.disabled && isElementVisible(radio)) {
                if (!groups.has(radio.name)) {
                    groups.set(radio.name, []);
                }
                groups.get(radio.name).push(radio);
            }
        });

        return groups;
    }

    // Mark field as error
    function markFieldAsError(field, message) {
        field.classList.add('app-field-error');
        
        // For radio buttons, mark the container
        if (field.type === 'radio') {
            const container = field.closest('.radio-group');
            if (container) {
                container.classList.add('app-field-error');
            }
        }

        // For nominee/joint holder cards
        const nomineeCard = field.closest('.nominee-card, .joint-block');
        if (nomineeCard) {
            nomineeCard.classList.add('app-field-error');
        }

        // Add error message if provided
        if (message && !field.nextElementSibling?.classList.contains('app-error-message')) {
            const errorSpan = document.createElement('span');
            errorSpan.className = 'app-error-message';
            errorSpan.textContent = message;
            field.parentNode.insertBefore(errorSpan, field.nextSibling);
        }
    }

    // Clear all errors in container
    function clearAllErrors(container) {
        container.querySelectorAll('.app-field-error').forEach(el => {
            el.classList.remove('app-field-error');
        });
        container.querySelectorAll('.app-error-message').forEach(el => {
            el.remove();
        });
    }

    // Clear errors on input change
    function setupFieldListeners() {
        document.addEventListener('input', function(e) {
            if (e.target.matches('input, select, textarea')) {
                e.target.classList.remove('app-field-error');
                const errorMsg = e.target.parentNode.querySelector('.app-error-message');
                if (errorMsg) errorMsg.remove();
                
                // Clear card error if inside nominee/joint holder
                const card = e.target.closest('.nominee-card, .joint-block');
                if (card) card.classList.remove('app-field-error');
            }
        });

        document.addEventListener('change', function(e) {
            if (e.target.type === 'radio') {
                const container = e.target.closest('.radio-group');
                if (container) {
                    container.classList.remove('app-field-error');
                }
            }
        });
    }

    // Initialize on DOM ready
    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', function() {
            initializeTabs();
            setupFieldListeners();
        });
    } else {
        initializeTabs();
        setupFieldListeners();
    }

})();