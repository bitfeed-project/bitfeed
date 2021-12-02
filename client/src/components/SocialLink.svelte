<script>
import Icon from '../components/Icon.svelte'

export let href
export let color
export let icon
</script>

<style type="text/scss">
.social-link {
  box-sizing: border-box;
  display: inline-flex;
  flex-direction: row;
  align-items: center;
  justify-content: flex-start;
  height: 2.0em;
  font-weight: bold;
  padding: .3em;
  border-radius: 1.0em;
  background: var(--bold-a);
  font-family: "Courier", monospace;
  color: white;

  .social-icon {
    width: 1.5em;
    height: 1.5em;
    font-size: 0.8em;
    padding: 0.1em;
    border-radius: 50%;
    display: flex;
    justify-content: center;
    align-items: center;
    background: white;
    margin-right: .5em;
  }

  .handle {
    margin-right: .5em;
  }
}
</style>

<a class="social-link" target="_blank" {href} rel="noopener" style="background: {color}">
  <span class="social-icon">
    <Icon {icon} {color}/>
  </span>
  <span class="handle"><slot /></span>
</a>
