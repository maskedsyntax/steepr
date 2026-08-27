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
    icon:
      "<rect x='6' y='6' width='12' height='12' rx='3.5'/><path d='M9 6V3.6h6V6M9 18v2.4h6V18M12 10v2.4l1.7 1'/>",
    title: 'Brew from your wrist',
    text: 'Start a favorite tea on Apple Watch, follow the active brew without your phone, and feel a clear haptic when it finishes.',
    detail: 'Watch app and face complications'
  },
  {
    icon:
      "<path d='M5 19c0-6.6 4.2-11 14-11 0 6.9-4.6 11.4-10.5 11.4H5Z'/><path d='M5.5 19.5C8 16 11 13.6 14.5 12'/>",
    title: 'Presets that know the tea',
    text: 'Eight built-in guides, from matcha and green to oolong, chai, and pu-erh, each with a suggested temperature and time.',
    detail: 'Plus custom teas with your own steps'
  },
  {
    icon:
      "<path d='M4.6 12a7.4 7.4 0 0 1 12.6-5.3l2.2 2.1'/><path d='M19.4 12a7.4 7.4 0 0 1-12.6 5.3l-2.2-2.1'/><path d='M19.4 4.4v4.4H15M4.6 19.6v-4.4H9'/>",
    title: 'Every infusion, right on time',
    text: 'Guided re-steeps dial in each later infusion, so gongfu sessions and second cups keep their timing.',
    detail: 'Multi-step heat, steep, and sip flows'
  },
  {
    icon:
      "<path d='M5 5.2A2 2 0 0 1 7 3.4h11.6v17.2H7A2 2 0 0 1 5 18.8Z'/><path d='M5 17.2h13.6'/><path d='M8.6 7.6h6.4M8.6 11h4.4'/>",
    title: 'Remember every cup',
    text: 'Brew history, tasting notes, and a daily caffeine total on the Brew tab keep the record of what you actually drank.',
    detail: 'History, notes, daily caffeine'
  },
  {
    icon:
      "<path d='M12 3.4a5.6 5.6 0 0 0-5.6 5.6c0 4-1.4 5.4-2 6.2h15.2c-.6-.8-2-2.2-2-6.2A5.6 5.6 0 0 0 12 3.4Z'/><path d='M10.2 18.4a2 2 0 0 0 3.6 0'/>",
    title: 'Visible without noise',
    text: 'Live Activities, the Dynamic Island, widgets, and Siri and Shortcuts keep the countdown one glance or one phrase away.',
    detail: 'Lock Screen, Home Screen, hands-free starts'
  },
  {
    icon:
      "<rect x='5.4' y='10.4' width='13.2' height='10.2' rx='2.6'/><path d='M8.6 10.4V7.8a3.4 3.4 0 0 1 6.8 0v2.6'/><path d='M12 14.4v2.4'/>",
    title: 'Private by design',
    text: 'No accounts, ads, analytics, or tracking. Your tea data stays local unless you choose iCloud sync with Pro.',
    detail: 'Local-first, optional private sync'
  }
]

const featureProof = [
  'Eight built-in tea guides',
  'Apple Watch app',
  'Watch complications',
  'Siri and Shortcuts',
  'Dynamic Island and Live Activities',
  'Daily caffeine total'
]

const screenshots = [
  {
    src: '/assets/steepr-screen-timer.png',
    alt: 'Steepr Brew screen with a Matcha countdown ring at 00:42, 75°C, infusion 1, pause and cancel controls, and a card for the next step.',
    caption: 'Live timer and next step'
  },
  {
    src: '/assets/steepr-screen-watch.png',
    alt: 'Steepr on Apple Watch showing a running Green tea timer at 2:19 with pause and cancel, beside a favorites list of Green, Black, and Oolong.',
    caption: 'Start from your wrist'
  },
  {
    src: '/assets/steepr-screen-library.png',
    alt: 'Steepr Library screen listing built-in guides for Matcha, Oolong, Pu-erh, Green, White, and Chai with steep times, temperatures, and favorite stars.',
    caption: 'Expert tea presets'
  },
  {
    src: '/assets/steepr-screen-infusions.png',
    alt: 'Steepr guided re-steep screen showing infusion 2 ready for Oolong, a session progress track, and a start infusion 3 button timed at 1:10.',
    caption: 'Re-steeps, already timed'
  },
  {
    src: '/assets/steepr-screen-history.png',
    alt: 'Steepr History screen showing 96 mg of caffeine across three brews today, recent Matcha, Oolong, and Green cups, and a tasting note field.',
    caption: 'History and daily caffeine'
  }
]

const steps = [
  { name: 'Pick a tea', detail: 'Green, black, oolong, white, herbal, chai, pu-erh, matcha, or your own custom profile, from iPhone, Apple Watch, or Siri.' },
  { name: 'Start steeping', detail: 'Steepr handles the countdown with pause, resume, cancel, and guided re-steeps for later infusions.' },
  { name: 'Enjoy the cup', detail: 'Notifications and haptics tell you when the timing is right, then history, tasting notes, and your daily caffeine total keep the record.' }
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
    text: 'Open Steepr on iPhone, or start a favorite straight from the Apple Watch app when your phone is across the room.'
  },
  {
    marker: '02',
    title: 'Ask instead of tapping',
    text: 'Siri and Shortcuts start a tea hands-free, which is useful when the kettle is already pouring.'
  },
  {
    marker: '03',
    title: 'Keep the timer visible',
    text: 'Live Activities, the Dynamic Island, Home and Lock Screen widgets, and Apple Watch complications keep the active brew nearby.'
  },
  {
    marker: '04',
    title: 'Know when the cup is ready',
    text: 'Completion notifications and haptics on iPhone and Apple Watch give a clear alert without repeated noise.'
  },
  {
    marker: '05',
    title: 'Sync the library with Pro',
    text: 'Private iCloud sync keeps teas, preferences, and brew history available across your Apple devices.'
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
    question: 'Does Steepr work on Apple Watch?',
    answer: 'Yes. The Apple Watch app starts favorite teas, follows the active brew, and gives a haptic when the timer finishes. Supported watch faces can show brew progress in a complication.'
  },
  {
    question: 'Can I start a brew with Siri or a Shortcut?',
    answer: 'Yes. Steepr provides App Intents, so you can start a tea by voice with Siri or from the Shortcuts app without opening Steepr.'
  },
  {
    question: 'How do guided re-steeps work?',
    answer: 'After an infusion finishes, Steepr offers the next one with its timing already adjusted, so oolong, pu-erh, and gongfu sessions stay on track. Guided re-steeps are part of Steepr Pro.'
  },
  {
    question: 'Where does the daily caffeine total come from?',
    answer: 'It is estimated from the teas you brewed today and shown on the Brew tab. It is a guide for your own reference, not a medical measurement.'
  },
  {
    question: 'How do I create a custom tea?',
    answer: 'Open the Library tab, choose to add a tea, then set the name, steep time, temperature, notes, color, and icon.'
  },
  {
    question: 'Why can I only create a few custom teas?',
    answer: 'The free version includes a small number of custom teas. Steepr Pro unlocks unlimited custom teas.'
  },
  {
    question: 'Do widgets, Live Activities, and the Dynamic Island follow the active timer?',
    answer: 'Yes. Widgets, Live Activities, and the Dynamic Island use a local shared timer snapshot so they show the current brew state.'
  },
  {
    question: 'Does Steepr sync with iCloud?',
    answer: 'Steepr Pro includes iCloud sync for teas, preferences, and brew history. Active timers remain local-only.'
  },
  {
    question: 'How do I restore Steepr Pro?',
    answer: 'Open Settings in Steepr and use Restore purchases. Purchases are restored through your Apple ID, and Pro is covered by Family Sharing.'
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
          <p class="eyebrow">Now on iPhone and Apple Watch</p>
          <h1>Perfect tea. No guesswork.</h1>
          <p class="hero-text">
            Steepr is a calm tea timer and brew guide for iPhone and Apple Watch.
            Choose your tea, follow a clear countdown, and get a gentle alert
            when every infusion is ready.
          </p>
          <div class="hero-actions" aria-label="Primary actions">
            <a class="button primary" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
            <a class="button secondary" href="#screenshots">See screenshots</a>
          </div>
        </div>

        <div class="device-stage" aria-label="Steepr on iPhone and Apple Watch">
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

          <div class="watch-mockup" aria-hidden="true">
            <span class="watch-crown"></span>
            <div class="watch-screen">
              <div class="watch-head">
                <span>Green</span>
                <span>12:52</span>
              </div>
              <div class="watch-ring">
                <span>2:19</span>
              </div>
              <div class="watch-actions">
                <span class="watch-pause">Ⅱ</span>
                <span class="watch-cancel">×</span>
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
            The app keeps the important details close: temperature and timing,
            favorites on iPhone and Apple Watch, guided re-steeps, brew history,
            and a timer you can follow from anywhere.
          </p>
        </div>
        <div class="screenshot-strip" aria-label="Steepr app screens">
          <figure v-for="screenshot in screenshots" :key="screenshot.src" class="screenshot-frame">
            <img
              :src="screenshot.src"
              :alt="screenshot.alt"
              width="720"
              height="1409"
              loading="lazy"
              decoding="async"
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
            Steepr keeps the core workflow close: pick the tea on whichever device
            is in reach, follow the time, get the alert, and keep a record of the
            cups you actually drank.
          </p>
        </div>
        <div class="feature-grid">
          <article v-for="feature in features" :key="feature.title" class="feature-card">
            <span class="feature-icon" aria-hidden="true">
              <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor"
                stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" v-html="feature.icon"></svg>
            </span>
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
            Steepr is built for the places Apple users expect a tea timer to appear:
            the iPhone app, the Apple Watch app and complications, Home and Lock Screen
            widgets, Live Activities and the Dynamic Island, Siri and Shortcuts,
            notifications, and haptics. Pro adds private iCloud sync for teas,
            preferences, and brew history.
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
            Use Steepr on iPhone and Apple Watch for expert tea presets, clear brew
            timers, guided re-steeps, brew history, and completion alerts.
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
      <p>© 2026 Aftaab Siddiqui. Steepr is built for iPhone and Apple Watch.</p>
      <div>
        <a href="/privacy/" @click="navigate($event, navItems[1])">Privacy</a>
        <a href="/support/" @click="navigate($event, navItems[2])">Support</a>
      </div>
    </footer>
  </div>
</template>
