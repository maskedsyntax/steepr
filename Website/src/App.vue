<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

const props = defineProps({
  page: {
    type: String,
    default: 'home'
  }
})

const navItems = [
  { label: 'Home', href: '/', page: 'home', title: 'Steepr - Calm Tea Timer for iPhone and Apple Watch' },
  { label: 'Privacy', href: '/privacy/', page: 'privacy', title: 'Privacy Policy - Steepr' },
  { label: 'Support', href: '/support/', page: 'support', title: 'Support - Steepr' }
]

const currentPage = ref(props.page)

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
  updateTitle()
  window.addEventListener('popstate', setPageFromPath)
})

onBeforeUnmount(() => {
  window.removeEventListener('popstate', setPageFromPath)
})

const features = [
  {
    title: 'Built for real tea routines',
    text: 'Save favorite teas, start a brew quickly, and let each steep run with a clear countdown.'
  },
  {
    title: 'Apple Watch first',
    text: 'Start favorites from your wrist, control the active timer, and feel gentle haptic alerts.'
  },
  {
    title: 'Visible without noise',
    text: 'Lock Screen widgets, Live Activities, and complications keep the timer nearby without opening the app.'
  },
  {
    title: 'Private by design',
    text: 'No accounts, no ads, no tracking. Your tea data stays local unless you choose iCloud sync with Pro.'
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
  'Advanced haptics and additional calm alert sounds',
  'Family Sharing support'
]

const teaPresets = [
  { name: 'Green', meta: '2m 30s · 80°C', tone: 'green' },
  { name: 'Black', meta: '4m · 95°C', tone: 'black' },
  { name: 'Oolong', meta: '3m 30s · 90°C', tone: 'oolong' },
  { name: 'Herbal', meta: '5m · 100°C', tone: 'herbal' }
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
    question: 'How do I use Steepr on Apple Watch?',
    answer: 'Favorite teas on iPhone appear on Apple Watch. Open Steepr on Apple Watch to start a favorite tea, control the timer, and receive haptic alerts.'
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
    </header>

    <Transition name="page-swap" mode="out-in">
    <main v-if="currentPage === 'home'" key="home">
      <section class="hero section-grid">
        <div class="hero-copy">
          <p class="eyebrow">iPhone and Apple Watch tea timer</p>
          <h1>The perfect cup, every time.</h1>
          <p class="hero-text">
            Steepr is a calm timer for people who want their tea routine to feel simple,
            precise, and Apple-native from phone to wrist.
          </p>
          <div class="hero-actions" aria-label="Primary actions">
            <a class="button primary" href="#notify">Available on the App Store soon</a>
            <a class="button secondary" href="/privacy/" @click="navigate($event, navItems[1])">Read privacy policy</a>
          </div>
        </div>

        <div class="device-stage" aria-label="Steepr iPhone and Apple Watch preview">
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
                  <span class="timer-time">4:30</span>
                </div>
              </div>
              <div class="brew-current">
                <strong>Herbal</strong>
                <span>100°C</span>
              </div>
              <div class="brew-actions">
                <span class="pause-action">Ⅱ Pause</span>
                <span class="cancel-action">× Cancel</span>
              </div>
              <div class="preset-peek">
                <div
                  v-for="tea in teaPresets"
                  :key="tea.name"
                  class="preset-tile"
                  :class="`tone-${tea.tone}`"
                >
                  <span class="preset-icon"></span>
                  <strong>{{ tea.name }}</strong>
                  <small>{{ tea.meta }}</small>
                </div>
              </div>
              <div class="tab-bar">
                <span class="active-tab"><b>☕</b><small>Brew</small></span>
                <span><b>▥</b><small>Library</small></span>
                <span><b>⚙</b><small>Settings</small></span>
              </div>
            </div>
          </div>
          <div class="watch-mockup" aria-hidden="true">
            <div class="watch-screen">
              <span class="watch-label">Watch</span>
              <strong>02:15</strong>
              <span>Green Tea</span>
              <div class="watch-progress"></div>
            </div>
          </div>
        </div>
      </section>

      <section class="feature-band" aria-labelledby="features-title">
        <div class="section-heading">
          <p class="eyebrow">Quietly capable</p>
          <h2 id="features-title">Everything needed for a better brew.</h2>
        </div>
        <div class="feature-grid">
          <article v-for="feature in features" :key="feature.title" class="feature-card">
            <h3>{{ feature.title }}</h3>
            <p>{{ feature.text }}</p>
          </article>
        </div>
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
            Steepr is built for the places Apple users expect timers to live:
            the iPhone, Apple Watch, Lock Screen, Live Activities, widgets, complications,
            notifications, haptics, and iCloud.
          </p>
        </div>
        <div class="platform-strip" aria-label="Supported Apple platforms">
          <span>iPhone</span>
          <span>Apple Watch</span>
          <span>Widgets</span>
          <span>Live Activities</span>
          <span>iCloud Sync</span>
        </div>
      </section>

      <section class="pro-band section-grid" aria-labelledby="pro-title">
        <div>
          <p class="eyebrow">Steepr Pro</p>
          <h2 id="pro-title">A one-time unlock for people who brew often.</h2>
          <p>
            The free app covers the core timer. Pro adds room for a larger tea library
            and private sync across your Apple devices.
          </p>
        </div>
        <ul class="check-list">
          <li v-for="item in proItems" :key="item">{{ item }}</li>
        </ul>
      </section>

      <section id="notify" class="final-cta" aria-labelledby="launch-title">
        <img src="/assets/steepr-logo-rounded.png" alt="" width="88" height="88" loading="lazy" />
        <div>
          <p class="eyebrow">Launching soon</p>
          <h2 id="launch-title">A calmer brew timer is on the way.</h2>
          <p>
            Steepr is being prepared for iPhone and Apple Watch. Privacy,
            support, and product details will stay available here as launch approaches.
          </p>
        </div>
      </section>
    </main>

    <main v-else-if="currentPage === 'privacy'" key="privacy" class="document-page">
      <section class="document-hero">
        <p class="eyebrow">Steepr</p>
        <h1>Privacy Policy</h1>
        <p>Effective date: To be updated before launch.</p>
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
          <p>For privacy questions, contact <a href="mailto:support@maskedsyntax.com">Aftaab Siddiqui</a>.</p>
        </article>
      </section>
    </main>

    <main v-else key="support" class="document-page">
      <section class="document-hero">
        <p class="eyebrow">Steepr</p>
        <h1>Support</h1>
        <p>
          For help with Steepr, contact
          <a href="mailto:support@maskedsyntax.com">Aftaab Siddiqui</a>.
        </p>
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
            Email <a href="mailto:support@maskedsyntax.com">Aftaab Siddiqui</a>
            with your device model, iOS or watchOS version, and a short description of the issue.
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
