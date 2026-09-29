var APP_GLOBAL = {
	
	devMode: false,
	cdkMode: false,
        clientSettingsEnabled: true,
	userClientBaseUrl: 'https://k7.inovatika.dev',
	deployPath: '',
	coreBaseUrl: 'https://k7.inovatika.dev/search',
	
	// cdk
	//userClientBaseUrl: 'https://ceskadigitalniknihovna.cz',
	// produkcni cdk
	//coreBaseUrl: 'https://api.ceskadigitalniknihovna.cz/search',
	
	// test / validacni cdk
	//coreBaseUrl: "https://api.val.ceskadigitalniknihovna.cz/search",

	languages:['cs','en','de','sk'],
	defaultLang: 'sk',
	

	keycloak: {
		loginType:'form',
		clientId: 'krameriusClient',
		logoutUrl:'https://eduid.inovatika.dev/realms/kramerius/protocol/openid-connect/logout?redirect_uri=https://admin.k7.inovatika.dev'
	},
	krameriusInstance: "kramerius7",
	proarc: [
		{
			name: "Produkce",
			domain: "https://proarc-master.inovatika.dev",
			krameriusInstance: "kramerius7" 
		},
		{
			name: "Stage",
			domain: "https://proarc-old.inovatika.dev",
			krameriusInstance: "kramerius7"
		},
		{
			name: "Testovací",
			domain: "https://proarc-old.inovatika.dev",
			krameriusInstance: "kramerius7"
		}
	],
	altoeditor: [
		{
			name: "Editor - Inovatika",
			domain: "https://altoeditor.inovatika.dev",
			krameriusInstance: "k7"

		}
	],
	homeDashboard: [
		{
			type: "object",
			hidden: true,
		},
		{
			type: "collections",	
			hidden: false,
		},
		{
			type: "indexing",
			subtype: "object",
			hidden: false		
		},
		{
			type: "indexing",
			subtype: "model",
			hidden: false
		},
		{
			type: "repository",
			subtype: "repository-management",
			hidden: false
		},
		{
			type: "repository",
			subtype: "bulk-data-editing",
			hidden: false
		},
		{
			type: "statistics",
			subtype: "graphs",
			hidden: false
		}
	]
}
