import svelte from 'rollup-plugin-svelte';
import commonjs from '@rollup/plugin-commonjs';
import resolve from '@rollup/plugin-node-resolve';
import livereload from 'rollup-plugin-livereload';
import { terser } from 'rollup-plugin-terser';
import glslify from 'rollup-plugin-glslify';
import css from 'rollup-plugin-css-only';
import sveltePreprocess from 'svelte-preprocess';
import { config as configDotenv } from 'dotenv';
import replace from '@rollup/plugin-replace';
import inlineSvg from 'rollup-plugin-inline-svg';
import html from '@rollup/plugin-html';
import copy from 'rollup-plugin-copy'
import babel from '@rollup/plugin-babel';
import fs from 'fs'

configDotenv();

const hash = String(require("child_process").execSync("git rev-parse --short HEAD")).trim();
const htmlOptions = {
	template: async ({ attributes, files, meta, publicPath, title }) => {
		const rawTemplate = fs.readFileSync('./template/index.html', { encoding: 'utf8', flag: 'r'})
		const scripts = (files.js || [])
			.map(({ fileName }) => {
				return `<script defer src='/${fileName}'></script>`;
			})
			.join('\n');

		const css = (files.css || [])
			.map(({ fileName }) => {
				return `<link rel='stylesheet' href='/${fileName}'>`;
			})
			.join('\n');
		let processed = rawTemplate.replace('{{css}}', css)
		processed = processed.replace('{{scripts}}', scripts)
		return processed
	}
}

const production = !process.env.ROLLUP_WATCH;

function serve() {
	let server;

	function toExit() {
		if (server) server.kill(0);
	}

	return {
		writeBundle() {
			if (server) return;
			server = require('child_process').spawn('npm', ['run', 'start', '--', '--dev'], {
				stdio: ['ignore', 'inherit', 'inherit'],
				shell: true
			});

			process.on('SIGTERM', toExit);
			process.on('exit', toExit);
		}
	};
}

export default {
	input: 'src/main.js',
	output: {
		sourcemap: true,
		format: 'iife',
		name: 'app',
		file: production ? `public/build/bundle.${hash}.js` : `public/build/bundle.js`
	},
	plugins: [
		replace({
			'ENVIRONMENT': JSON.stringify(process.env.ENV)
		}),
		inlineSvg({
			removeTags: false,
			removingTags: ['title', 'desc', 'defs', 'style'],
			removeSVGTagAttrs: true
		}),
		svelte({
			compilerOptions: {
				// enable run-time checks when not in production
				dev: !production
			},
			preprocess: sveltePreprocess()
		}),
		babel({
			extensions: [ ".js", ".mjs", ".html", ".svelte" ]
		}),
		// we'll extract any component CSS out into
		// a separate file - better for performance
		css({ output: production ? `bundle.${hash}.css` : 'bundle.css' }),
		production && html(htmlOptions),
		production && copy({
			targets: [
				{ src: 'public/*.*', dest: 'public/build' },
				{ src: 'public/img', dest: 'public/build' }
			]
		}),

		// If you have external dependencies installed from
		// npm, you'll most likely need these plugins. In
		// some cases you'll need additional configuration -
		// consult the documentation for details:
		// https://github.com/rollup/plugins/tree/master/packages/commonjs
		resolve({
			browser: true,
			dedupe: ['svelte']
		}),
		commonjs(),

		// In dev mode, call `npm run start` once
		// the bundle has been generated
		!production && serve('public'),

		// Watch the `public` directory and refresh the
		// browser on changes when not in production
		!production && livereload('public'),

		// If we're building for production (npm run build
		// instead of npm run dev), minify
		production && terser(),
		glslify()
	],
	watch: {
		clearScreen: false
	}
};
