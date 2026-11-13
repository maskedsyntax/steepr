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
  const themeColor = resolvedTheme.value === 'dark' ? '#1b1713' : '#f3f5ef'
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

const themeCycleOrder = ['system', 'light', 'dark']

const selectedThemeLabel = computed(() => {
  return themeModes.find((mode) => mode.value === selectedTheme.value)?.label ?? 'System'
})

const cycleTheme = () => {
  const index = themeCycleOrder.indexOf(selectedTheme.value)
  setTheme(themeCycleOrder[(index + 1) % themeCycleOrder.length])
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

// Real presets from the app's built-in library. Liquor colors approximate each brewed cup.
const steepTeas = [
  { name: 'Gyokuro', family: 'Green', temperature: 60, time: '1:30', taste: 'Rich and umami', liquor: '#c3cc78' },
  { name: 'Sencha', family: 'Green', temperature: 75, time: '2:00', taste: 'Fresh and grassy', liquor: '#a9b04a' },
  { name: 'Silver Needle', family: 'White', temperature: 80, time: '3:00', taste: 'Soft and sweet', liquor: '#dcc47c' },
  { name: 'Tieguanyin', family: 'Oolong', temperature: 90, time: '3:30', taste: 'Floral and creamy', liquor: '#cf9530' },
  { name: 'Assam', family: 'Black', temperature: 95, time: '4:00', taste: 'Bold and malty', liquor: '#983f12' },
  { name: 'Ripe Pu-erh', family: 'Pu-erh', temperature: 100, time: '3:00', taste: 'Deep and smooth', liquor: '#4b1d0c' }
]

const selectedTeaIndex = ref(1)
const steepRun = ref(0)
const selectedTea = computed(() => steepTeas[selectedTeaIndex.value])

const steepTea = (index) => {
  selectedTeaIndex.value = index
  steepRun.value += 1
}

const screenshots = [
  {
    src: '/assets/steepr-screen-quick-picks-1.5.png',
    alt: 'Steepr Brew screen with one-tap Quick Picks for Green, Black, Oolong, Matcha, Herbal, and Chai.',
    caption: 'Start a cup in one tap'
  },
  {
    src: '/assets/steepr-screen-timer-1.4.png',
    alt: 'Steepr active tea timer with a clear countdown, water temperature, and pause and finish controls.',
    caption: 'Follow a clear countdown'
  },
  {
    src: '/assets/steepr-screen-watch.png',
    alt: 'Steepr on Apple Watch showing a running Green tea timer at 2:19 with pause and cancel, beside a favorites list of Green, Black, and Oolong.',
    caption: 'Start from your wrist'
  },
  {
    src: '/assets/steepr-screen-library-1.5.png',
    alt: 'Steepr Library screen with search and tea families, including the expanded green, black, oolong, white, herbal, and pu-erh guides.',
    caption: 'Browse 52 guided teas'
  },
  {
    src: '/assets/steepr-screen-personal-timing-1.4.png',
    alt: 'Steepr tasting feedback screen for saving a better steep time after a cup.',
    caption: 'Save a better time for next cup'
  }
]

const steps = [
  { name: 'Pick a tea', detail: 'Start a Quick Pick, search 52 built-in guides, or choose your own tea from iPhone, Apple Watch, or Siri.' },
  { name: 'Start steeping', detail: 'Steepr runs the countdown with pause, resume, and cancel, and keeps it on your Lock Screen and wrist.' },
  { name: 'Enjoy the cup', detail: 'A gentle alert tells you the tea is ready. Re-steep the same leaves, or note how the cup tasted.' }
]

const features = [
  {
    icon:
      "<rect x='6' y='6' width='12' height='12' rx='3.5'/><path d='M9 6V3.6h6V6M9 18v2.4h6V18M12 10v2.4l1.7 1'/>",
    title: 'Brew from your wrist',
    text: 'Start a favorite tea on Apple Watch, follow the brew without your phone, and feel a haptic when it finishes.'
  },
  {
    icon:
      "<path d='M5 19c0-6.6 4.2-11 14-11 0 6.9-4.6 11.4-10.5 11.4H5Z'/><path d='M5.5 19.5C8 16 11 13.6 14.5 12'/>",
    title: 'Presets that know the tea',
    text: '52 guides, from everyday green and black tea to Gyokuro, oolong, herbal infusions, and pu-erh. Add your own teas too.'
  },
  {
    icon:
      "<path d='M4.6 12a7.4 7.4 0 0 1 12.6-5.3l2.2 2.1'/><path d='M19.4 12a7.4 7.4 0 0 1-12.6 5.3l-2.2-2.1'/><path d='M19.4 4.4v4.4H15M4.6 19.6v-4.4H9'/>",
    title: 'Every infusion on time',
    text: 'Guided re-steeps adjust each later infusion, so gongfu sessions and second cups keep their timing.'
  },
  {
    icon:
      "<path d='M5 5.2A2 2 0 0 1 7 3.4h11.6v17.2H7A2 2 0 0 1 5 18.8Z'/><path d='M5 17.2h13.6'/><path d='M8.6 7.6h6.4M8.6 11h4.4'/>",
    title: 'Remember every cup',
    text: 'Brew history and tasting notes keep what you enjoyed. Say a cup was too weak or too strong, and save a better time.'
  },
  {
    icon:
      "<path d='M12 3.4a5.6 5.6 0 0 0-5.6 5.6c0 4-1.4 5.4-2 6.2h15.2c-.6-.8-2-2.2-2-6.2A5.6 5.6 0 0 0 12 3.4Z'/><path d='M10.2 18.4a2 2 0 0 0 3.6 0'/>",
    title: 'Visible at a glance',
    text: 'Live Activities, the Dynamic Island, widgets, and Siri keep the countdown one glance or one phrase away.'
  },
  {
    icon:
      "<rect x='5.4' y='10.4' width='13.2' height='10.2' rx='2.6'/><path d='M8.6 10.4V7.8a3.4 3.4 0 0 1 6.8 0v2.6'/><path d='M12 14.4v2.4'/>",
    title: 'Private by design',
    text: 'No accounts, ads, analytics, or tracking. Your tea data stays on your device unless you turn on iCloud sync.'
  }
]

const proItems = [
  'Unlimited custom teas',
  'iCloud sync for teas, preferences, and brew history',
  'Full brew journal with tasting notes',
  'Guided re-steeps for later infusions',
  'Stronger completion haptic option',
  'Family Sharing support'
]

const privacySections = [
  {
    title: 'Data Steepr stores',
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
    title: 'Where data is stored',
    body: 'By default, Steepr stores app data locally on your device. If you use Steepr Pro and iCloud sync is enabled, Steepr syncs teas, preferences, and brew history using Apple CloudKit in your private iCloud database. Active timer state is local-only and is not synced through iCloud.'
  },
  {
    title: 'Data Steepr does not collect',
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
    title: 'Data deletion',
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
    question: 'Can I change a suggested steep time?',
    answer: 'Yes. Edit a tea profile directly, or save a personal time after a cup tastes too weak or too strong.'
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
  <div class="site">
    <a class="skip-link" href="#content">Skip to content</a>

    <header class="site-header">
      <div class="wrap header-row">
        <a class="brand" href="/" aria-label="Steepr home" @click="navigate($event, navItems[0])">
          <img src="/assets/steepr-logo-rounded.png" alt="" width="36" height="36" />
          <span>Steepr</span>
        </a>

        <nav class="site-nav" aria-label="Primary navigation">
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

        <div class="header-actions">
          <button
            class="theme-toggle"
            type="button"
            :aria-label="`Color theme: ${selectedThemeLabel}. Change theme.`"
            :title="`Theme: ${selectedThemeLabel}`"
            @click="cycleTheme"
          >
            <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor"
              stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
              <template v-if="selectedTheme === 'light'">
                <circle cx="12" cy="12" r="4" />
                <path d="M12 2.5v2M12 19.5v2M4.6 4.6 6 6M18 18l1.4 1.4M2.5 12h2M19.5 12h2M4.6 19.4 6 18M18 6l1.4-1.4" />
              </template>
              <path v-else-if="selectedTheme === 'dark'" d="M20 14.5A8 8 0 0 1 9.5 4a8 8 0 1 0 10.5 10.5Z" />
              <template v-else>
                <circle cx="12" cy="12" r="8.5" />
                <path d="M12 3.5v17a8.5 8.5 0 0 0 0-17Z" fill="currentColor" stroke="none" />
              </template>
            </svg>
          </button>
          <a class="button button-small header-download" :href="appStoreUrl" target="_blank" rel="noopener">Get the app</a>
        </div>
      </div>
    </header>

    <Transition name="page-swap" mode="out-in">
      <main v-if="currentPage === 'home'" id="content" key="home">
        <section class="hero wrap" aria-labelledby="hero-title">
          <div class="hero-copy">
            <h1 id="hero-title">The right time and temperature for every tea.</h1>
            <p class="lede">
              Steepr guides 52 teas from kettle to cup on iPhone and Apple Watch.
              Pick a tea, tap start, and get a gentle alert when it’s ready.
            </p>
            <div class="hero-actions">
              <a class="button button-primary" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
              <p class="hero-note">Free, with an optional one-time Pro upgrade.</p>
            </div>
          </div>

          <figure class="cup-stage" :style="{ '--liquor': selectedTea.liquor }">
            <div class="cup" aria-hidden="true">
              <svg class="steep-ring" viewBox="0 0 100 100" :key="`ring-${steepRun}`">
                <circle class="steep-ring-track" cx="50" cy="50" r="48" />
                <circle class="steep-ring-fill" cx="50" cy="50" r="48" pathLength="100" />
              </svg>
              <div class="saucer"></div>
              <div class="cup-handle"></div>
              <div class="cup-rim">
                <div class="liquor" :key="`liquor-${steepRun}`"></div>
              </div>
            </div>
            <figcaption class="cup-caption" aria-live="polite">
              <span class="cup-name">{{ selectedTea.name }}</span>
              <span class="cup-spec">
                <span>{{ selectedTea.temperature }}°C water</span>
                <span>{{ selectedTea.time }} steep</span>
              </span>
            </figcaption>
          </figure>
        </section>

        <section class="steep-scale wrap" aria-labelledby="scale-title">
          <div class="section-intro">
            <h2 id="scale-title">Every leaf steeps differently.</h2>
            <p>
              Each guide carries its own water temperature and steep time, from cool,
              short Gyokuro to boiling-hot pu-erh. Tap a tea to steep it.
            </p>
          </div>
          <ul class="scale-list">
            <li v-for="(tea, index) in steepTeas" :key="tea.name">
              <button
                type="button"
                class="scale-tea"
                :style="{ '--liquor': tea.liquor }"
                :aria-pressed="selectedTeaIndex === index"
                @click="steepTea(index)"
              >
                <span class="scale-swatch" aria-hidden="true"></span>
                <span class="scale-family">{{ tea.family }}</span>
                <span class="scale-name">{{ tea.name }}</span>
                <span class="scale-meta">{{ tea.temperature }}°C, {{ tea.time }}</span>
                <span class="scale-taste">{{ tea.taste }}</span>
              </button>
            </li>
          </ul>
        </section>

        <section id="screenshots" class="screens" aria-labelledby="screens-title">
          <div class="wrap">
            <div class="section-intro">
              <h2 id="screens-title">Made for iPhone and Apple Watch.</h2>
              <p>One clear screen at each step, with the timer close at hand wherever you are.</p>
            </div>
          </div>
          <div class="screens-track" tabindex="0" aria-label="App screenshots, scroll for more">
            <figure v-for="screenshot in screenshots" :key="screenshot.src" class="screen">
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

        <section class="steps wrap" aria-labelledby="steps-title">
          <h2 id="steps-title">From kettle to cup in three steps.</h2>
          <ol class="step-list">
            <li v-for="step in steps" :key="step.name">
              <h3>{{ step.name }}</h3>
              <p>{{ step.detail }}</p>
            </li>
          </ol>
        </section>

        <section class="features wrap" aria-labelledby="features-title">
          <div class="features-intro">
            <h2 id="features-title">The details that make a better cup.</h2>
            <p>Steepr keeps the whole brew close: the tea, the time, the alert, and a record of what you drank.</p>
          </div>
          <ul class="feature-list">
            <li v-for="feature in features" :key="feature.title">
              <svg viewBox="0 0 24 24" width="24" height="24" fill="none" stroke="currentColor"
                stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"
                v-html="feature.icon"></svg>
              <h3>{{ feature.title }}</h3>
              <p>{{ feature.text }}</p>
            </li>
          </ul>
        </section>

        <section class="pro wrap" aria-labelledby="pro-title">
          <div class="pro-panel">
            <div class="pro-copy">
              <h2 id="pro-title">Steepr Pro is one purchase. No subscription.</h2>
              <p>
                The free app covers the timer, all 52 guides, and a few custom teas.
                Pro is for people who brew often and want everything to follow them.
              </p>
            </div>
            <ul class="pro-list">
              <li v-for="item in proItems" :key="item">{{ item }}</li>
            </ul>
          </div>
        </section>

        <section class="closing wrap" aria-labelledby="closing-title">
          <img src="/assets/steepr-logo-rounded.png" alt="" width="96" height="96" loading="lazy" />
          <h2 id="closing-title">Brew your next cup with Steepr.</h2>
          <a class="button button-primary" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
          <p class="closing-note">
            Steepr is made by one independent developer. If it makes your tea calmer,
            you can <a :href="koFiUrl" target="_blank" rel="noopener">buy me a coffee</a>.
          </p>
        </section>
      </main>

      <main v-else-if="currentPage === 'privacy'" id="content" key="privacy" class="doc wrap">
        <header class="doc-header">
          <h1>Privacy Policy</h1>
          <p class="lede">Steepr is designed to collect as little information as possible.</p>
          <p class="doc-meta">Effective June 5, 2026</p>
        </header>

        <div class="doc-body">
          <section v-for="section in privacySections" :key="section.title" class="doc-section">
            <h2>{{ section.title }}</h2>
            <p v-if="section.body">{{ section.body }}</p>
            <ul v-if="section.items">
              <li v-for="item in section.items" :key="item">{{ item }}</li>
            </ul>
          </section>
          <section class="doc-section">
            <h2>Contact</h2>
            <p>For privacy questions, email <a href="mailto:support@maskedsyntax.com">support@maskedsyntax.com</a>.</p>
          </section>
        </div>
      </main>

      <main v-else id="content" key="support" class="doc wrap">
        <header class="doc-header">
          <h1>Support</h1>
          <p class="lede">
            Email <a href="mailto:support@maskedsyntax.com">support@maskedsyntax.com</a>
            with your device model, iOS version, and a short description of the issue.
          </p>
        </header>

        <div class="doc-body">
          <h2 class="faq-title">Common questions</h2>
          <details v-for="faq in faqs" :key="faq.question" class="faq">
            <summary>{{ faq.question }}</summary>
            <p>{{ faq.answer }}</p>
          </details>
          <a class="button button-primary doc-download" :href="appStoreUrl" target="_blank" rel="noopener">Download on the App Store</a>
        </div>
      </main>
    </Transition>

    <footer class="site-footer">
      <div class="wrap footer-row">
        <p>© 2026 Aftaab Siddiqui. Steepr is built for iPhone and Apple Watch.</p>
        <nav aria-label="Footer">
          <a href="/privacy/" @click="navigate($event, navItems[1])">Privacy</a>
          <a href="/support/" @click="navigate($event, navItems[2])">Support</a>
          <a :href="appStoreUrl" target="_blank" rel="noopener">App Store</a>
        </nav>
      </div>
    </footer>
  </div>
</template>
