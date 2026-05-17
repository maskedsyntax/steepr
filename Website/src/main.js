import { createApp } from 'vue'
import './styles.css'
import App from './App.vue'

const page = document.body.dataset.page || 'home'

createApp(App, { page }).mount('#app')
