<script>
	import TxViz from './components/TxViz.svelte'
	import analytics from './utils/analytics.js'
	import config from './config.js'
	import { settings } from './stores.js'

	if (!$settings.noTrack && config.public) analytics.init()
</script>

<main>
	<TxViz />
</main>

<style>
	main {
		text-align: center;
		margin: 0 auto;
	}

	@media (min-width: 640px) {
		main {
			max-width: none;
		}
	}

</style>
