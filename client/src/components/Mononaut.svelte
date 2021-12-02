<script>

</script>

<style type="text/css">
.mononaut {
  position: relative;
  width: 100%;
}

.mononaut .aspect {
  width: 100%;
  padding-bottom: 100%;
}

.mononaut .inner {
  position: absolute;
  top: 0;
  right: 0;
  bottom: 0;
  left: 0;
  width: 100%;
  height: 100%;
  display: flex;
  justify-content: center;
  align-items: center;

  border-radius: 50%;
  background: linear-gradient(45deg, darkviolet, transparent 100%);
}

.mononaut .avatar {
  width: 80%;
  height: 80%;
  margin-left: 5%;
  margin-top: 5%;
}

#monkey {
  transform-origin: center;
  --rock-amplitude: 8deg;
  animation-name: rock;
  animation-duration: 5s;
  animation-iteration-count: infinite;
}

.monkey-eye {
  transform-origin: center;
  animation-name: blink;
  animation-duration: 8s;
  animation-delay: -2s;
  animation-iteration-count: infinite;
}

#ear-left {
  transform-origin: 80% 50%;
  --rock-amplitude: 20deg;
  animation-name: rock;
  animation-duration: 3s;
  animation-iteration-count: infinite;
}

@keyframes rock {
  0% {
    transform: rotate(0deg);
  }
  50% {
    transform: rotate(var(--rock-amplitude));
  }
  100% {
    transform: rotate(0deg);
  }
}

@keyframes blink {
  0% {
    transform: none;
  }
  48% {
    transform: none;
  }
  50% {
    transform: matrix(1,-0.3,0.04,0.2,0,6);
  }
  52% {
    transform: none;
  }
  100% {
    transform: none;
  }
}
</style>

<div class="mononaut">
  <div class="aspect">
    <div class="inner">
      <svg class="avatar"
         width="334.47833"
         height="360.19266"
         viewBox="0 0 88.497389 95.30098"
         version="1.1"
         id="svg8">
        <defs
           id="defs2">
          <linearGradient
             id="linearGradient1874">
            <stop
               style="stop-color:#ffffff;stop-opacity:0.65887851"
               offset="0"
               id="stop1870" />
            <stop
               style="stop-color:#a7a7a7;stop-opacity:0;"
               offset="1"
               id="stop1872" />
          </linearGradient>
          <linearGradient
             xlink:href="#linearGradient1874"
             id="linearGradient5760"
             gradientUnits="userSpaceOnUse"
             gradientTransform="matrix(0.88559909,0,0,0.88559909,2.1865141,-1.4202934)"
             x1="74.399529"
             y1="16.307785"
             x2="15.273721"
             y2="83.253212" />
        </defs>
        <g
           style="display:inline;opacity:1"
           transform="translate(-10.793731,-5.4097061)">
          <path
             style="display:inline;opacity:1;fill:#576c78;fill-opacity:1;stroke:none;stroke-width:0.71934628;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
             d="m 61.651061,20.553894 1.289922,1.959392 C 59.55236,29.73164 61.960527,32.936832 62.291817,37.57986 69.580914,51.34937 46.284973,74.005931 38.794339,77.275048 18.383317,86.182975 8.0562438,56.701838 11.97544,33.820946 13.409936,25.446125 24.242237,4.0376168 61.651061,20.553894 Z"
             id="visor-back" />
          <path
             style="fill:#784421;fill-opacity:1;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
             d="m 40.023612,69.217407 c -1.74228,14.114255 19.884147,12.868589 29.800552,15.568451 l 13.964832,-13.8312 C 77.167852,62.564819 61.700977,53.269993 49.110776,59.796156 Z"
             id="monkey-body" />
          <g id="monkey">
            <g
               style="display:inline"
               id="monkey-inner"
               transform="matrix(0.73793571,0.19032465,-0.19032465,0.73793571,8.5451128,-1.5971534)">
              <path
                 id="ear-right"
                 d="m 35.094888,56.21721 c -6.89655,2.534431 -14.53992,-2.389386 -17.231469,-4.852391 1.23186,-3.401999 4.604949,-5.92599 8.722879,-7.236581 1.66704,-0.53056 3.45615,-0.862263 5.27469,-0.97286 9.17189,1.090452 10.68783,11.787228 3.2339,13.0061832 z"
                 style="display:inline;opacity:1;fill:#deaa87;stroke:none;stroke-width:0.21957469px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <path
                 id="head"
                 d="m 30.308872,23.862935 c -7.896397,9.705521 -12.701615,16.830049 -7.269507,28.957925 4.3062,9.614141 -0.284703,11.721588 5.683872,18.251035 5.45108,5.55247 10.178022,5.892849 13.988071,13.594771 11.299136,14.269193 22.409786,3.337588 26.080359,-5.85863 C 81.867477,56.071791 88.32321,34.989715 70.681545,21.166667 55.190177,12.328814 46.139739,12.585053 30.308872,23.862935 Z"
                 style="display:inline;fill:#784421;fill-opacity:1;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <g id="ear-left">
                <path
                   id="ear-left-outer"
                   d="m 77.833423,50.323879 c 6.47703,-6.03607 5.34152,-16.93279 4.15774,-21.16667 -6.07997,-0.73952 -12.59596,4.00709 -16.44197,10.58333 -3.8176,10.45458 6.85846,17.904101 12.28423,10.58334 z"
                   style="display:inline;opacity:1;fill:#deaa87;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
                 <path
                    id="ear-left-inner"
                    d="m 76.76206,47.72753 c 4.556293,-4.246097 3.757513,-11.911438 2.924778,-14.889778 -4.276979,-0.520219 -8.860678,2.818803 -11.56617,7.444885 -2.685506,7.354316 4.824612,12.594712 8.641392,7.444893 z"
                    style="display:inline;opacity:1;fill:#e9c6af;stroke:none;stroke-width:0.18612219px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              </g>
              <path
                 id="face"
                 d="m 38.742559,49.51488 c 1.45629,-4.066862 6.298841,-7.992738 12.284225,-6.992558 15.425741,4.293009 4.803701,19.409911 -2.976563,18.473584 18.639296,3.573862 22.324617,26.346482 6.174076,27.17782 -12.717835,0.34267 -8.581608,-9.318628 -16.409445,-12.0269 -5.597227,-1.936527 -2.05593,-13.668839 -2.663067,-12.26885 -6.589222,8.759543 -12.047332,-0.849447 -11.528273,-9.921875 1.774561,-2.871137 4.819803,-3.699497 8.882439,-1.039433 4.789983,2.254962 5.346565,-0.781825 6.236608,-3.401788 z"
                 style="display:inline;fill:#deaa87;fill-opacity:1;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <path
                 id="muzzle"
                 d="M 60.072997,75.352317 C 55.003352,70.027191 55.75107,68.927121 53.34848,66.485233 51.841457,64.88184 47.05277,62.630654 42.069361,63.849024 c -1.699146,0.415416 -4.449014,1.385616 -6.199235,3.299959 -1.682918,1.84073 -1.025774,7.464219 2.777696,9.202331 3.896358,1.78056 4.087632,2.791893 5.88943,6.981181 3.630032,8.440037 20.554285,1.586752 15.535745,-7.980178 z"
                 style="display:inline;fill:#502d16;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <path
                 id="face-inner"
                 d="m 38.957003,52.607487 c 1.042028,-2.641197 2.728748,-4.7652 10.223515,-5.17104 7.241178,0.814991 8.551291,5.869414 4.817338,8.574224 -3.147594,3.346452 -6.33337,3.393592 -8.935703,2.930689 -3.51048,-0.180022 -6.925621,-0.202977 -8.446902,2.89418 -5.220943,5.911145 -10.282881,0.05394 -10.31162,-5.662332 1.650862,-1.605418 3.81304,-2.437929 7.455186,-1.033305 4.247946,1.104042 4.568382,-0.833998 5.198186,-2.532416 z"
                 style="display:inline;fill:#e9c6af;stroke:none;stroke-width:0.19504021px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <path
                 id="mouth"
                 d="m 42.472928,76.398309 c -0.995545,-0.575317 -0.253436,-2.698662 1.044456,-2.998078 4.228867,-0.975576 12.597117,-0.526341 13.187645,0.826512 1.454954,3.573662 -4.175521,8.756925 -10.256469,8.652853 -2.374181,0.259391 -1.069921,-4.879679 -3.975632,-6.481287 z"
                 style="display:inline;fill:#28170b;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <path
                 id="tongue"
                 d="m 46.929215,76.246574 c 0.615399,-1.75537 8.22103,-2.28337 7.216279,4.07586 -0.212053,1.37525 3.358405,1.46548 4.409948,3.34086 1.055887,4.79323 -3.65884,4.36937 -6.94901,2.77293 -4.202979,-2.19163 -5.874033,-5.47644 -4.677217,-10.18965 z"
                 style="display:inline;opacity:1;fill:#da789c;fill-opacity:1;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              <g id="eye-left" class="monkey-eye">
                <path
                   id="pupil-left"
                   d="m 40.867285,57.273873 c 1.612375,-2.042551 0.701258,-3.847919 2.827551,-5.020606 2.852266,-1.245289 3.874257,0.02912 6.461358,-0.487557 -1.800708,1.927123 -1.087836,3.182768 -3.147949,4.379153 -2.48621,1.342919 -2.404803,0.48141 -6.14096,1.12901 z"
                   style="display:inline;fill:#28170b;fill-opacity:1;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
                <path
                   id="gleam-left"
                   d="m 44.577763,52.357009 0.175397,1.00226 1.720546,-0.91874 z"
                   style="display:inline;opacity:1;fill:#f4e3d7;fill-opacity:1;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              </g>
              <g id="eye-right" class="monkey-eye">
                <path
                   id="pupil-right"
                   d="m 36.526068,59.323301 c -2.29866,-0.610735 -2.053402,-2.430637 -4.251391,-2.123454 -2.768843,0.651852 -2.383872,2.077275 -4.559515,3.116838 2.373186,0.423104 2.10538,1.799062 4.267942,1.545474 2.554554,-0.379861 1.455015,-0.965477 4.542964,-2.538858 z"
                   style="display:inline;fill:#28170b;stroke:none;stroke-width:0.24182333px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
                <path
                   id="gleam-right"
                   d="m 31.608594,58.036779 0.803199,0.56105 0.750048,-0.48428 z"
                   style="display:inline;opacity:1;fill:#f4e3d7;stroke:none;stroke-width:0.26458332px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1" />
              </g>
            </g>
          </g>
          <g id="helmet">
            <path
               style="display:inline;opacity:1;fill:#22676d;fill-opacity:1;stroke:none;stroke-width:0.23431474px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
               d="M 88.570396,58.724343 C 94.62432,54.067131 100.74234,57.883387 98.984914,64.996727 95.801343,75.095656 65.800904,103.41999 49.515946,100.50077 42.891637,97.739253 46.341916,92.001209 46.32058,88.666096 Z"
               id="collar-one" />
            <path
               style="display:inline;opacity:1;fill:#bae5e9;fill-opacity:1;stroke:none;stroke-width:0.23431474px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
               d="M 83.372436,52.659423 C 89.426364,48.002211 95.544387,51.818467 93.786951,58.931806 90.603382,69.030735 60.602943,97.355073 44.317985,94.435853 37.693676,91.674335 41.143955,85.936289 41.122619,82.601171 Z"
               id="collar-two" />
            <path
               style="display:inline;opacity:1;fill:#bae5e9;fill-opacity:1;stroke:none;stroke-width:0.23431474px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
               d="M 28.23215,79.916507 C 40.765843,80.993896 69.099088,55.590613 62.481792,37.486127 59.618529,29.652427 61.621394,25.326412 63.0048283,22.398281 63.451782,21.570257 62.431545,21.170567 61.660924,20.582972 58.721936,18.342009 33.314523,9.1801348 21.414153,19.148253 21.040806,19.46098 16.493514,24.225612 16.466931,23.906261 16.284334,21.712654 15.7061,18.778538 16.842454,17.601749 28.272105,5.7653958 43.244764,5.2528968 51.182613,5.4345318 74.64048,5.9712998 76.979428,18.408564 78.673549,18.329111 92.064018,29.246088 95.017703,40.802051 86.539829,53.0057904 73.279621,74.932862 61.561047,80.045597 49.802622,87.117228 40.441364,90.882866 24.536108,90.048641 21.648484,74.844071 c 2.995365,2.722164 2.788093,4.347644 6.583666,5.072436 z"
               id="helmet-case" />
            <path
               style="display:inline;opacity:1;fill:#22676d;fill-opacity:1;stroke:none;stroke-width:0.23431474px;stroke-linecap:butt;stroke-linejoin:miter;stroke-opacity:1"
               d="m 38.50793,85.407931 c 1.842704,-0.411794 2.387542,-0.346584 3.341095,-0.04751 4.084771,1.281151 4.96339,0.781298 6.513681,0.03974 7.412447,-4.138988 13.715592,-9.704221 19.57263,-15.84302 l 0.241658,-11.116412 c -0.0621,-0.767793 -0.0058,-1.485505 0.329786,-2.085218 l 9.16256,-15.933883 c 1.483253,-4.949488 3.702339,-12.396219 3.313375,-17.72015 -0.162002,-2.217387 -1.329754,-1.991515 -2.30917,-4.372385 13.390473,10.916977 16.344158,22.47294 7.866281,34.728794 -13.26021,21.874955 -24.978782,26.987686 -36.737206,34.059324 -9.361257,3.765637 -18.488123,1.257736 -21.626797,-1.059526 4.264979,0.370603 6.29984,0.400653 10.332107,-0.649754 z"
               id="helmet-base" />
            <ellipse
               style="display:inline;opacity:1;fill:#133a3e;fill-opacity:1;stroke:none;stroke-width:0.24935082;stroke-linecap:round;stroke-linejoin:round;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
               id="helmet-joint"
               cx="53.400845"
               cy="67.588089"
               rx="6.4156117"
               ry="9.9880085"
               transform="matrix(0.88495557,-0.46567547,0.48925229,0.8721423,0,0)" />
            <path
               style="display:inline;opacity:0.98000004;fill:url(#linearGradient5760);fill-opacity:1;stroke:#000000;stroke-width:0.71934628;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
               d="m 61.651061,20.553894 1.289918,1.959392 C 59.552359,29.73164 61.960527,32.936833 62.291817,37.57986 69.580918,51.349372 46.284972,74.005931 38.794337,77.275049 18.383317,86.182977 8.0562438,56.70184 11.97544,33.820947 13.409936,25.446126 24.242237,4.0376178 61.651061,20.553894 Z"
               id="visor" />
             <path
                style="display:inline;opacity:0.753;fill:#ffffff;fill-opacity:1;stroke:none;stroke-width:0.23431474;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-opacity:1"
                d="m 35.84597,19.072302 c 7.774683,-2.280832 13.824223,-0.609922 19.290532,2.95867 l 1.301816,4.023793 c -8.1156,-3.761618 -15.343244,-5.578561 -23.314324,-3.432059 z"
                id="helmet-gleam" />
          </g>
        </g>
      </svg>
    </div>
  </div>
</div>
