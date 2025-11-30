module.exports = {
	presets: [
		[
		'@babel/preset-env',
		{
			useBuiltIns: 'usage',
			corejs: '{ version: 3, proposals: true }',
			targets: {
				browsers: ['ast 2 versions', 'ie >= 11'],
				},
			},
		],
		[
			'@babel/preset-react',
			{
				runtime: 'automatic',
			},
		],
		'@babel/preset-typescript',
		],
		plugins: [
			'@babel/plugin-syntax-dynamic-import',
			'@babel/plugin-proposal-class-properties',
			'@babel/plugin-transform-runtime',
		],
};
