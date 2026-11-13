import { createApp } from 'vue'
import '@fontsource-variable/newsreader/opsz.css'
import '@fontsource-variable/figtree'
import './styles.css'
import App from './App.vue'

const page = document.body.dataset.page || 'home'

createApp(App, { page }).mount('#app')
