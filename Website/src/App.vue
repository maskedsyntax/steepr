<script setup>
import { onBeforeUnmount, onMounted, ref } from 'vue'

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
    text: 'Choose a tea preset, save favorites, start a brew quickly, and let each steep run with a clear countdown.'
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

const screenshots = [
  {
    src: '/assets/steepr-app-store-frame-1.jpg',
    alt: 'Steepr tea timer showing built-in green, black, oolong, herbal, chai, and matcha presets.',
    caption: 'Tea presets'
  },
  {
    src: '/assets/steepr-app-store-frame-2.jpg',
    alt: 'Steepr brew screen with a one tap oolong countdown timer, pause control, and cancel control.',
    caption: 'One tap timer'
  },
  {
    src: '/assets/steepr-app-store-frame-3.jpg',
    alt: 'Steepr tea library with favorite teas, steeping times, and brewing temperatures.',
    caption: 'Tea library'
  },
  {
    src: '/assets/steepr-app-store-frame-4.jpg',
    alt: 'Steepr settings for brew history, temperature units, pre-completion alerts, sounds, and haptics.',
    caption: 'Personal settings'
  },
  {
    src: '/assets/steepr-app-store-frame-5.jpg',
    alt: 'Steepr Pro screen showing iCloud sync, unlimited custom teas, advanced haptics, and more sounds.',
    caption: 'Steepr Pro'
  },
  {
    src: '/assets/steepr-app-store-frame-6.jpg',
    alt: 'Steepr Apple Watch screens for starting favorite tea timers and controlling an active brew.',
    caption: 'Apple Watch'
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

const ecosystemItems = [
  {
    marker: '01',
    title: 'Start from the device in reach',
    text: 'Use Steepr on iPhone, or start favorite teas directly from Apple Watch.'
  },
  {
    marker: '02',
    title: 'Keep the timer visible',
    text: 'Home Screen widgets, Lock Screen widgets, Live Activities, and Watch complications keep the active brew nearby.'
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
          <p class="eyebrow">Now available on the App Store</p>
          <h1>The perfect cup, every time.</h1>
          <p class="hero-text">
            Steepr is a calm tea timer for iPhone and Apple Watch. Start a preset,
            follow a clear countdown, and get gentle alerts when your tea is ready.
          </p>
          <div class="hero-actions" aria-label="Primary actions">
            <a class="button primary" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
            <a class="button secondary" href="#screenshots">See screenshots</a>
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
            <div class="watch-screen">
              <div class="watch-top">
                <span>Steepr</span>
                <strong>3:27</strong>
              </div>
              <div class="watch-tea-list">
                <div class="watch-tea-row watch-green">
                  <span class="watch-tea-icon"></span>
                  <div>
                    <strong>Green</strong>
                    <small>2m 30s</small>
                  </div>
                </div>
                <div class="watch-tea-row watch-black">
                  <span class="watch-tea-icon"></span>
                  <div>
                    <strong>Black</strong>
                    <small>4m</small>
                  </div>
                </div>
                <div class="watch-tea-row watch-oolong">
                  <span class="watch-tea-icon"></span>
                  <div>
                    <strong>Oolong</strong>
                    <small>3m 30s</small>
                  </div>
                </div>
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
            favorites, Watch controls, notifications, and simple settings.
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
            Steepr is built for the places Apple users expect tea timers to appear:
            iPhone, Apple Watch, Home Screen widgets, Lock Screen widgets, Live Activities,
            Watch complications, notifications, and haptics. Pro adds private iCloud sync
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
          <p class="eyebrow">Available now</p>
          <h2 id="launch-title">Download Steepr from the App Store.</h2>
          <p>
            Use Steepr on iPhone and Apple Watch for simple tea presets,
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
          <p>For privacy questions, contact <a href="mailto:aftaab@aftaab.dev">Aftaab Siddiqui</a>.</p>
        </article>
      </section>
    </main>

    <main v-else key="support" class="document-page">
      <section class="document-hero">
        <p class="eyebrow">Steepr</p>
        <h1>Support</h1>
        <p>
          For help with Steepr, contact
          <a href="mailto:aftaab@aftaab.dev">Aftaab Siddiqui</a>.
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
            Email <a href="mailto:aftaab@aftaab.dev">Aftaab Siddiqui</a>
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
