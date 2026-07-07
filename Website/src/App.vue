<script setup>
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'

const props = defineProps({
  page: {
    type: String,
    default: 'home'
  }
})

const navItems = [
  { label: 'Home', href: '/', page: 'home', title: 'Steepr Tea Timer - Download on the App Store' },
  { label: 'Privacy', href: '/privacy/', page: 'privacy', title: 'Privacy Policy - Steepr' },
  { label: 'Support', href: '/support/', page: 'support', title: 'Support - Steepr' }
]

const currentPage = ref(props.page)
const appStoreUrl = 'https://apps.apple.com/us/app/steepr/id6775478425'
const koFiUrl = 'https://ko-fi.com/aftaabsiddiqui'
const themeStorageKey = 'steepr-theme'
const themeModes = [
  { value: 'light', label: 'Light' },
  { value: 'dark', label: 'Dark' },
  { value: 'system', label: 'System' }
]
const selectedTheme = ref('system')
const systemTheme = ref('light')
let systemThemeQuery

const resolvedTheme = computed(() => {
  return selectedTheme.value === 'system' ? systemTheme.value : selectedTheme.value
})

const getStoredTheme = () => {
  try {
    return localStorage.getItem(themeStorageKey)
  } catch {
    return null
  }
}

const persistTheme = (theme) => {
  try {
    if (theme === 'system') localStorage.removeItem(themeStorageKey)
    else localStorage.setItem(themeStorageKey, theme)
  } catch {
    // The selected theme still applies for the current page view.
  }
}

const updateThemeColor = () => {
  const themeColor = resolvedTheme.value === 'dark' ? '#111410' : '#f7faf4'
  document.querySelectorAll('meta[name="theme-color"]').forEach((meta) => {
    meta.setAttribute('content', themeColor)
  })
}

const applyTheme = () => {
  document.documentElement.dataset.theme = resolvedTheme.value
  document.documentElement.style.colorScheme = resolvedTheme.value
  updateThemeColor()
}

const setTheme = (theme) => {
  if (!themeModes.some((mode) => mode.value === theme)) return
  selectedTheme.value = theme
  persistTheme(theme)
  applyTheme()
}

const updateSystemTheme = () => {
  systemTheme.value = systemThemeQuery?.matches ? 'dark' : 'light'
  if (selectedTheme.value === 'system') applyTheme()
}

const setPageFromPath = () => {
  const path = window.location.pathname
  if (path.startsWith('/privacy')) currentPage.value = 'privacy'
  else if (path.startsWith('/support')) currentPage.value = 'support'
  else currentPage.value = 'home'
  updateTitle()
}

const updateTitle = () => {
  const navItem = navItems.find((item) => item.page === currentPage.value)
  if (navItem) document.title = navItem.title
}

const navigate = (event, item) => {
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return
  if ('button' in event && event.button !== 0) return
  event.preventDefault()
  if (currentPage.value === item.page) return

  currentPage.value = item.page
  window.history.pushState({}, '', item.href)
  updateTitle()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(() => {
  const savedTheme = getStoredTheme()
  if (themeModes.some((mode) => mode.value === savedTheme)) selectedTheme.value = savedTheme
  systemThemeQuery = window.matchMedia('(prefers-color-scheme: dark)')
  updateSystemTheme()
  systemThemeQuery.addEventListener('change', updateSystemTheme)
  applyTheme()

  updateTitle()
  window.addEventListener('popstate', setPageFromPath)
})

onBeforeUnmount(() => {
  systemThemeQuery?.removeEventListener('change', updateSystemTheme)
  window.removeEventListener('popstate', setPageFromPath)
})

const features = [
  {
    icon: '􀐫',
    title: 'Built for real tea routines',
    text: 'Choose a preset, save favorites, and start the next brew with a clear countdown.',
    detail: 'Presets, custom teas, pause, resume'
  },
  {
    icon: '􀋃',
    title: 'Favorites stay close',
    text: 'Keep regular teas on the Brew tab, with the full library ready when you want something different.',
    detail: 'One-tap starts for daily cups'
  },
  {
    icon: '􀐭',
    title: 'Visible without noise',
    text: 'Live Activities, widgets, notifications, and clear in-app states keep timing easy to follow.',
    detail: 'Useful on the Lock Screen and Home Screen'
  },
  {
    icon: '􀎡',
    title: 'Private by design',
    text: 'No accounts, ads, or tracking. Your tea data stays local unless you choose iCloud sync with Pro.',
    detail: 'Local-first, optional private sync'
  }
]

const featureProof = [
  'Built-in tea presets',
  'Custom profiles',
  'Brew history',
  'Live Activities'
]

const screenshots = [
  {
    src: '/assets/steepr-mockup-calm-way.svg',
    alt: 'Steepr onboarding screen introducing a calmer way to make tea with Heat, Steep, Sip, and Repeat steps.',
    caption: 'Calm onboarding'
  },
  {
    src: '/assets/steepr-mockup-favorite-tea.svg',
    alt: 'Steepr Brew screen showing favorite tea presets with steep times and temperatures.',
    caption: 'Favorite teas'
  },
  {
    src: '/assets/steepr-mockup-perfect-timing.svg',
    alt: 'Steepr active Matcha timer with countdown ring, temperature, infusion number, pause control, and cancel control.',
    caption: 'Perfect timing'
  },
  {
    src: '/assets/steepr-mockup-gentle-alert.svg',
    alt: 'Steepr completion screen showing Matcha is ready with re-steep and done actions.',
    caption: 'Gentle alerts'
  },
  {
    src: '/assets/steepr-mockup-tea-library.svg',
    alt: 'Steepr Library screen showing a custom tea and built-in teas with favorites, steep times, and temperatures.',
    caption: 'Tea library'
  }
]

const steps = [
  { name: 'Pick a tea', detail: 'Green, black, oolong, white, herbal, chai, pu-erh, matcha, or your own custom profile.' },
  { name: 'Start steeping', detail: 'Steepr handles the countdown with pause, resume, cancel, and brew-again controls.' },
  { name: 'Enjoy the cup', detail: 'Optional pre-alerts and completion notifications tell you when the timing is right.' }
]

const proItems = [
  'Unlimited custom teas',
  'iCloud sync for teas, preferences, and brew history',
  'Full brew journal with tasting notes',
  'Guided re-steeps for later infusions',
  'Stronger completion haptic option',
  'Family Sharing support'
]

const ecosystemItems = [
  {
    marker: '01',
    title: 'Start from the device in reach',
    text: 'Open Steepr on iPhone, then start a favorite tea or browse the full library.'
  },
  {
    marker: '02',
    title: 'Keep the timer visible',
    text: 'Home Screen widgets, Lock Screen widgets, and Live Activities keep the active brew nearby.'
  },
  {
    marker: '03',
    title: 'Know when the cup is ready',
    text: 'Completion notifications and haptics give a clear alert without repeated noise.'
  },
  {
    marker: '04',
    title: 'Sync the library with Pro',
    text: 'Private iCloud sync keeps teas, preferences, and brew history available across Apple devices.'
  }
]

const privacySections = [
  {
    title: 'Data Steepr Stores',
    items: [
      'Tea profiles you create or edit.',
      'Favorite teas.',
      'Brewing preferences.',
      'Brew history.',
      'Active timer state.',
      'Purchase entitlement state for Steepr Pro.'
    ]
  },
  {
    title: 'Where Data Is Stored',
    body: 'By default, Steepr stores app data locally on your device. If you use Steepr Pro and iCloud sync is enabled, Steepr syncs teas, preferences, and brew history using Apple CloudKit in your private iCloud database. Active timer state is local-only and is not synced through iCloud.'
  },
  {
    title: 'Data Steepr Does Not Collect',
    items: [
      'Analytics or tracking data.',
      'Advertising identifiers.',
      'Location.',
      'Contacts.',
      'Health data.',
      'Account credentials.',
      'Personal notes outside the tea notes you choose to enter.'
    ]
  },
  {
    title: 'Notifications',
    body: 'If you allow notifications, Steepr uses them only for tea timer alerts, including optional pre-completion alerts and brew completion alerts.'
  },
  {
    title: 'Purchases',
    body: 'Steepr Pro purchases are handled by Apple through StoreKit. Steepr receives purchase entitlement status from Apple, but does not receive your payment information.'
  },
  {
    title: 'Data Deletion',
    body: 'You can delete custom teas and brew history in the app. Deleting the app removes local app data from the device. If iCloud sync is enabled, data stored in iCloud may remain available to your Apple ID according to Apple’s iCloud behavior.'
  }
]

const faqs = [
  {
    question: 'How do I create a custom tea?',
    answer: 'Open the Library tab, choose to add a tea, then set the name, steep time, temperature, notes, color, and icon.'
  },
  {
    question: 'Why can I only create a few custom teas?',
    answer: 'The free version includes a small number of custom teas. Steepr Pro unlocks unlimited custom teas.'
  },
  {
    question: 'Do widgets and Live Activities sync with the active timer?',
    answer: 'Yes. Widgets and Live Activities use a local shared timer snapshot so they can show the current brew state.'
  },
  {
    question: 'Does Steepr sync with iCloud?',
    answer: 'Steepr Pro includes iCloud sync for teas, preferences, and brew history. Active timers remain local-only.'
  },
  {
    question: 'How do I restore Steepr Pro?',
    answer: 'Open Settings in Steepr and use Restore purchases. Purchases are restored through your Apple ID.'
  }
]
</script>

<template>
  <div class="site-shell">
    <header class="site-header">
      <a class="brand" href="/" aria-label="Steepr home" @click="navigate($event, navItems[0])">
        <img src="/assets/steepr-logo-rounded.png" alt="" width="40" height="40" />
        <span>Steepr</span>
      </a>
      <nav class="nav-tabs" :class="`nav-${currentPage}`" aria-label="Primary navigation">
        <span class="nav-indicator" aria-hidden="true"></span>
        <a
          v-for="item in navItems"
          :key="item.href"
          :href="item.href"
          :aria-current="currentPage === item.page ? 'page' : undefined"
          @click="navigate($event, item)"
        >
          {{ item.label }}
        </a>
      </nav>
      <div class="theme-switcher" aria-label="Color theme">
        <button
          v-for="mode in themeModes"
          :key="mode.value"
          type="button"
          :aria-pressed="selectedTheme === mode.value"
          @click="setTheme(mode.value)"
        >
          {{ mode.label }}
        </button>
      </div>
    </header>

    <Transition name="page-swap" mode="out-in">
    <main v-if="currentPage === 'home'" key="home">
      <section class="hero section-grid">
        <div class="hero-copy">
          <p class="eyebrow">Now available on the App Store</p>
          <h1>The perfect cup, every time.</h1>
          <p class="hero-text">
            Steepr is a calm tea timer for iPhone. Start a preset,
            follow a clear countdown, and get gentle alerts when your tea is ready.
          </p>
          <div class="hero-actions" aria-label="Primary actions">
            <a class="button primary" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
            <a class="button secondary" href="#screenshots">See screenshots</a>
          </div>
        </div>

        <div class="device-stage" aria-label="Steepr iPhone preview">
          <div class="phone-mockup" aria-hidden="true">
            <div class="dynamic-island"></div>
            <div class="phone-screen">
              <div class="status-row">
                <span>9:42</span>
                <span class="status-icons">•••• 􀙇</span>
              </div>
              <div class="app-title">
                Brew
              </div>
              <div class="timer-orbit">
                <div class="timer-ring">
                  <span class="timer-time">2:49</span>
                </div>
              </div>
              <div class="brew-current">
                <strong>Oolong</strong>
                <span>90°C</span>
                <small>Infusion 1</small>
              </div>
              <div class="brew-actions">
                <span class="pause-action">Ⅱ Pause</span>
                <span class="cancel-action">× Cancel</span>
              </div>
            </div>
          </div>
        </div>
      </section>

      <section id="screenshots" class="screenshot-band" aria-labelledby="screenshots-title">
        <div class="section-heading">
          <p class="eyebrow">Inside Steepr</p>
          <h2 id="screenshots-title">A quiet workflow from tea choice to final alert.</h2>
          <p>
            The app keeps the important details close: steeping time, temperature,
            favorites, notifications, and simple settings.
          </p>
        </div>
        <div class="screenshot-strip" aria-label="Steepr app screenshots">
          <figure v-for="screenshot in screenshots" :key="screenshot.src" class="screenshot-frame">
            <img
              :src="screenshot.src"
              :alt="screenshot.alt"
              width="900"
              height="1947"
              loading="lazy"
            />
            <figcaption>{{ screenshot.caption }}</figcaption>
          </figure>
        </div>
      </section>

      <section class="feature-band" aria-labelledby="features-title">
        <div class="feature-intro">
          <div class="section-heading">
            <p class="eyebrow">Quietly capable</p>
            <h2 id="features-title">Everything needed for a better brew.</h2>
          </div>
          <p>
            Steepr keeps the core workflow close: pick the tea, follow the time,
            get the alert, and come back to your usual cups without extra setup.
          </p>
        </div>
        <div class="feature-grid">
          <article v-for="feature in features" :key="feature.title" class="feature-card">
            <span class="feature-icon" aria-hidden="true">{{ feature.icon }}</span>
            <h3>{{ feature.title }}</h3>
            <p>{{ feature.text }}</p>
            <small>{{ feature.detail }}</small>
          </article>
        </div>
        <ul class="feature-proof" aria-label="Steepr capabilities">
          <li v-for="item in featureProof" :key="item">{{ item }}</li>
        </ul>
      </section>

      <section class="workflow section-grid" aria-labelledby="workflow-title">
        <div>
          <p class="eyebrow">Designed around the ritual</p>
          <h2 id="workflow-title">Fast enough for daily tea, clear enough for careful tea.</h2>
        </div>
        <ol class="step-list">
          <li v-for="step in steps" :key="step.name">
            <span>{{ step.name }}</span>
            <p>{{ step.detail }}</p>
          </li>
        </ol>
      </section>

      <section class="apple-panel" aria-labelledby="ecosystem-title">
        <div>
          <p class="eyebrow">Apple ecosystem</p>
          <h2 id="ecosystem-title">Native surfaces, familiar behavior.</h2>
          <p>
            Steepr is built for the places iPhone users expect tea timers to appear:
            the app, Home Screen widgets, Lock Screen widgets, Live Activities,
            notifications, and haptics. Pro adds private iCloud sync
            for teas, preferences, and brew history.
          </p>
        </div>
        <div class="ecosystem-list" aria-label="Supported Apple surfaces">
          <article v-for="item in ecosystemItems" :key="item.title" class="ecosystem-item">
            <span>{{ item.marker }}</span>
            <div>
              <h3>{{ item.title }}</h3>
              <p>{{ item.text }}</p>
            </div>
          </article>
        </div>
      </section>

      <section class="pro-band section-grid" aria-labelledby="pro-title">
        <div>
          <p class="eyebrow">Steepr Pro</p>
          <h2 id="pro-title">A one-time unlock for people who brew often.</h2>
          <p>
            The free app covers the core timer and a small custom tea library. Pro adds
            unlimited custom teas, a full brew journal, guided re-steeps, stronger haptics,
            and private sync across your Apple devices.
          </p>
        </div>
        <ul class="check-list">
          <li v-for="item in proItems" :key="item">{{ item }}</li>
        </ul>
      </section>

      <section class="support-band" aria-labelledby="support-title">
        <div class="support-mark" aria-hidden="true">
          <span></span>
        </div>
        <div>
          <p class="eyebrow">Support independent apps</p>
          <h2 id="support-title">Enjoying Steepr?</h2>
          <p>
            Steepr is built and maintained independently. If it makes your tea routine
            calmer, you can support future updates with a small coffee.
          </p>
        </div>
        <a class="button support-button" :href="koFiUrl" target="_blank" rel="noopener">Buy me a coffee</a>
      </section>

      <section id="notify" class="final-cta" aria-labelledby="launch-title">
        <img src="/assets/steepr-logo-rounded.png" alt="" width="88" height="88" loading="lazy" />
        <div>
          <p class="eyebrow">Available now</p>
          <h2 id="launch-title">Download Steepr from the App Store.</h2>
          <p>
            Use Steepr on iPhone for simple tea presets,
            clear brew timers, favorite teas, and completion alerts.
          </p>
        </div>
        <a class="button cta-button" :href="appStoreUrl" target="_blank" rel="noopener">Open App Store</a>
      </section>
    </main>

    <main v-else-if="currentPage === 'privacy'" key="privacy" class="document-page">
      <section class="document-hero">
        <p class="eyebrow">Steepr</p>
        <h1>Privacy Policy</h1>
        <p>Effective date: June 5, 2026.</p>
        <p>Steepr is designed to collect as little information as possible.</p>
      </section>

      <section class="document-content" aria-label="Privacy policy details">
        <article v-for="section in privacySections" :key="section.title" class="document-section">
          <h2>{{ section.title }}</h2>
          <p v-if="section.body">{{ section.body }}</p>
          <ul v-if="section.items">
            <li v-for="item in section.items" :key="item">{{ item }}</li>
          </ul>
        </article>
        <article class="document-section">
          <h2>Contact</h2>
          <p>For privacy questions, contact <a href="mailto:support@maskedsyntax.com">support@maskedsyntax.com</a>.</p>
        </article>
      </section>
    </main>

    <main v-else key="support" class="document-page">
      <section class="document-hero">
        <p class="eyebrow">Steepr</p>
        <h1>Support</h1>
        <p>
          For help with Steepr, contact
          <a href="mailto:support@maskedsyntax.com">support@maskedsyntax.com</a>.
        </p>
        <div class="document-actions">
          <a class="button primary" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
        </div>
      </section>

      <section class="document-content" aria-labelledby="faq-title">
        <h2 id="faq-title" class="faq-title">Common Questions</h2>
        <article v-for="faq in faqs" :key="faq.question" class="document-section">
          <h3>{{ faq.question }}</h3>
          <p>{{ faq.answer }}</p>
        </article>
        <article class="document-section">
          <h3>How do I contact support?</h3>
          <p>
            Email <a href="mailto:support@maskedsyntax.com">support@maskedsyntax.com</a>
            with your device model, iOS version, and a short description of the issue.
          </p>
        </article>
      </section>
    </main>
    </Transition>

    <footer class="site-footer">
      <p>© 2026 Aftaab Siddiqui. Steepr is built for iPhone.</p>
      <div>
        <a href="/privacy/" @click="navigate($event, navItems[1])">Privacy</a>
        <a href="/support/" @click="navigate($event, navItems[2])">Support</a>
      </div>
    </footer>
  </div>
</template>
