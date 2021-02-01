<script>
	import TxMap from './components/TxMap.svelte'
</script>

<main>
	<TxMap />
</main>

<style>
	main {
		text-align: center;
		max-width: 240px;
		margin: 0 auto;
	}

	@media (min-width: 640px) {
		main {
			max-width: none;
		}
	}
</style>
