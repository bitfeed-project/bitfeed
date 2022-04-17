<style type="text/scss">
.wrapper {
  width: 100%;
  position: relative;
  overflow: hidden;
  box-sizing: border-box;
  border-radius: 50%;
  border: solid 2px var(--palette-x);

  .sizer {
    width: 100%;
    padding-bottom: 100%;
  }
}
.bf-loader .inner .mempool {
	width: 150%;
	height: 150%;
	position: absolute;
	left: -25%;
	right: -25%;
	bottom: 0;
}

.bf-loader .tx {
	position: absolute;
	top: -10%;
	width: 10%;
	height: 10%;
	animation-duration: 10s;
	animation-timing-function: linear;
	animation-iteration-count: infinite;
}
.bf-loader .tx .tx-inner {
	background: var(--loading-color);
	width: 80%;
	height: 80%;
	position: absolute;
	left: 0;
	bottom: 0;
}
.bf-loader .tx.large .tx-inner {
	width: 180%;
	height: 180%;
}
.bf-loader .tx.a { animation-name: txa; animation-delay: -10s; }
.bf-loader .tx.b { animation-name: txb; animation-delay: -9s; }
.bf-loader .tx.c { animation-name: txc; animation-delay: -8s; }
.bf-loader .tx.d { animation-name: txd; animation-delay: -7s; }
.bf-loader .tx.e { animation-name: txe; animation-delay: -6s; }
.bf-loader .tx.f { animation-name: txf; animation-delay: -5s; }
.bf-loader .tx.g { animation-name: txg; animation-delay: -4s; }
.bf-loader .tx.h { animation-name: txh; animation-delay: -3s; }
.bf-loader .tx.i { animation-name: txi; animation-delay: -2s; }
.bf-loader .tx.j { animation-name: txj; animation-delay: -1s; }
@keyframes txa {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  43% { transform: translateY(900%); }
  48% { transform: translateY(1000%); }
  63% { transform: translateY(1000%); }
  68% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
@keyframes txb {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  33% { transform: translateY(900%); }
  38% { transform: translateY(1000%); }
  53% { transform: translateY(1000%); }
  58% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
@keyframes txc {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  23% { transform: translateY(900%); }
  28% { transform: translateY(1000%); }
  43% { transform: translateY(1000%); }
  48% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
@keyframes txd {
  0% { transform: translateY(0); }
  20% { transform: translateY(1000%); }
  33% { transform: translateY(1000%); }
  38% { transform: translateY(1100%); }
  53% { transform: translateY(1100%); }
  58% { transform: translateY(1200%); }
  100% { transform: translateY(1200%); }
}
@keyframes txe {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  23% { transform: translateY(900%); }
  28% { transform: translateY(1000%); }
  43% { transform: translateY(1000%); }
  48% { transform: translateY(1100%); }
  73% { transform: translateY(1100%); }
  78% { transform: translateY(1200%); }
  100% { transform: translateY(1200%); }
}
@keyframes txf {
  0% { transform: translateY(0); }
  20% { transform: translateY(1000%); }
  33% { transform: translateY(1000%); }
  38% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
@keyframes txg {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  23% { transform: translateY(900%); }
  28% { transform: translateY(1000%); }
  53% { transform: translateY(1000%); }
  58% { transform: translateY(1100%); }
  83% { transform: translateY(1100%); }
  88% { transform: translateY(1200%); }
  100% { transform: translateY(1200%); }
}
@keyframes txh {
  0% { transform: translateY(0); }
  20% { transform: translateY(1000%); }
  43% { transform: translateY(1000%); }
  48% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
@keyframes txi {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  33% { transform: translateY(900%); }
  38% { transform: translateY(1000%); }
  63% { transform: translateY(1000%); }
  68% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
@keyframes txj {
  0% { transform: translateY(0); }
  20% { transform: translateY(900%); }
  23% { transform: translateY(900%); }
  28% { transform: translateY(1000%); }
  53% { transform: translateY(1000%); }
  58% { transform: translateY(1100%); }
  100% { transform: translateY(1100%); }
}
</style>

<div class="wrapper">
  <div class="sizer" />
  <div class="bf-loader">
    <div class="mempool">
      <div class="tx small a" style="left: 25%;"><div class="tx-inner"></div></div>
      <div class="tx small b" style="left: 35%;"><div class="tx-inner"></div></div>
      <div class="tx small c" style="left: 45%;"><div class="tx-inner"></div></div>
      <div class="tx large d" style="left: 55%;"><div class="tx-inner"></div></div>
      <div class="tx large e" style="left: 25%;"><div class="tx-inner"></div></div>
      <div class="tx small f" style="left: 45%;"><div class="tx-inner"></div></div>
      <div class="tx large g" style="left: 45%;"><div class="tx-inner"></div></div>
      <div class="tx small h" style="left: 65%;"><div class="tx-inner"></div></div>
      <div class="tx small i" style="left: 25%;"><div class="tx-inner"></div></div>
      <div class="tx small j" style="left: 35%;"><div class="tx-inner"></div></div>
      <div class="tx small j" style="left: 65%;"><div class="tx-inner"></div></div>
    </div>
  </div>
</div>
