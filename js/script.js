// ===============================
// Debug Configuration
// ===============================
const DEBUG = true;

function log(message, style = '') {
    if (DEBUG) console.log(`%c${message}`, style);
}

function warn(message) {
    if (DEBUG) console.warn(message);
}

function error(message) {
    if (DEBUG) console.error(message);
}

// ===============================
// Script Loaded Timestamp
// ===============================
const currentDate = new Date();
const formattedDate = currentDate.toISOString().slice(0, 19).replace('T', ' ');
log(`Script loaded at (UTC): ${formattedDate}`, 'color: green; font-weight: bold;');

// ===============================
// Modal Analytics (Session Only)
// ===============================
let modalOpenCount = 0;

// ===============================
// Article Expansion Logic
// ===============================

// Wait for DOM ready
if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', () => {
        populatePreviewGrid().then(initArticleModal);
    });
} else {
    populatePreviewGrid().then(initArticleModal);
}

/* Fetch and render up to three posts into the home preview grid */
function populatePreviewGrid() {
    return fetch('posts/places/posts-places.json')
        .then(r => r.json())
        .then(data => {
            const container = document.querySelector('#preview-grid');
            if (!container) return;
            container.innerHTML = '';
            data.slice(0, 3).forEach(post => {
                const article = document.createElement('article');
                article.className = 'card';
                // keep the post object handy for later
                article._post = post;

                const h2 = document.createElement('h2');
                h2.className = 'card-title';
                h2.textContent = post.title;
                article.appendChild(h2);

                const meta = document.createElement('time');
                meta.className = 'meta';
                meta.textContent = post.city;
                article.appendChild(meta);

                const p = document.createElement('p');
                p.className = 'excerpt';
                p.textContent = post.description;
                article.appendChild(p);

                const full = document.createElement('div');
                full.className = 'full-text';
                full.hidden = true;
                const fullp = document.createElement('p');
                fullp.textContent = post.description;
                full.appendChild(fullp);
                article.appendChild(full);

                const btn = document.createElement('button');
                btn.className = 'btn read-btn';
                btn.textContent = 'Read';
                article.appendChild(btn);

                container.appendChild(article);
            });
        })
        .catch(err => {
            console.error('Failed to load preview posts:', err);
        });
}

function initArticleModal() {
    log('Initializing article modal system...', 'color: green;');

    const readButtons = document.querySelectorAll('.read-btn');
    log(`Found ${readButtons.length} read buttons`, 'color: blue;');

    if (readButtons.length === 0) {
        warn('No read buttons found on page.');
    }

    readButtons.forEach(btn => {
        btn.addEventListener('click', (e) => {
            log('Read button clicked', 'color: purple;');

            const card = e.currentTarget.closest('.card, .review-card');
            if (!card) {
                warn('No card found for clicked button.');
                return;
            }

            const title = card.querySelector('h2, h3');
            if (title) {
                log(`Opening article: ${title.textContent.trim()}`, 'color: blue; font-weight: bold;');
            } else {
                warn('No title found inside card.');
            }

            openModalWithCard(card);
        });
    });
}

function openModalWithCard(card) {
    if (DEBUG) console.time('Modal Render Time');

    modalOpenCount++;
    log(`Modal opened ${modalOpenCount} times this session`, 'color: orange;');

    const post = card._post || {};

    const overlay = document.createElement('div');
    overlay.className = 'modal-overlay fade-in';

    const modal = document.createElement('div');
    modal.className = 'modal-content slide-in';

    // close button
    const closeBtn = document.createElement('button');
    closeBtn.textContent = '×';
    closeBtn.setAttribute('aria-label', 'Close');
    closeBtn.style.cssText = `
        position:absolute;
        top:8px;
        right:12px;
        font-size:1.4rem;
        background:none;
        border:none;
        cursor:pointer;
        color:var(--text-secondary);
    `;
    closeBtn.addEventListener('click', () => {
        if (document.body.contains(overlay)) {
            document.body.removeChild(overlay);
            log('Modal closed via button', 'color: red;');
        }
    });

    // add image slider if there are images
    if (post.images && post.images.length > 0) {
        const slider = document.createElement('div');
        slider.className = 'image-slider';
        let idx = 0;
        const imgEl = document.createElement('img');
        imgEl.src = post.images[0];
        imgEl.className = 'slider-img';
        slider.appendChild(imgEl);
        const prevBtn = document.createElement('button');
        prevBtn.className = 'slider-control prev';
        prevBtn.textContent = '<';
        const nextBtn = document.createElement('button');
        nextBtn.className = 'slider-control next';
        nextBtn.textContent = '>';
        prevBtn.addEventListener('click', () => {
            idx = (idx - 1 + post.images.length) % post.images.length;
            imgEl.src = post.images[idx];
        });
        nextBtn.addEventListener('click', () => {
            idx = (idx + 1) % post.images.length;
            imgEl.src = post.images[idx];
        });
        slider.appendChild(prevBtn);
        slider.appendChild(nextBtn);
        modal.appendChild(slider);
    }

    // build content clone after slider
    const clone = card.cloneNode(true);
    const btn = clone.querySelector('.read-btn');
    if (btn) btn.remove();
    const full = clone.querySelector('.full-text');
    if (full) {
        full.removeAttribute('hidden');
        full.style.display = 'block';
    }

    modal.appendChild(closeBtn);
    modal.appendChild(clone);

    // close when clicking outside content
    overlay.addEventListener('click', (evt) => {
        if (evt.target === overlay) {
            document.body.removeChild(overlay);
            log('Modal closed via overlay click', 'color: red;');
        }
    });

    const escHandler = (evt) => {
        if (evt.key === 'Escape' && document.body.contains(overlay)) {
            document.body.removeChild(overlay);
            document.removeEventListener('keydown', escHandler);
            log('Modal closed via Escape key', 'color: red;');
        }
    };
    document.addEventListener('keydown', escHandler);

    overlay.appendChild(modal);
    document.body.appendChild(overlay);

    if (DEBUG) console.timeEnd('Modal Render Time');
}
