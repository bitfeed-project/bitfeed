<script>
	import TxViz from './components/TxViz.svelte'
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
