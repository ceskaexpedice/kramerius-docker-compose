var APP_GLOBAL = {	
	devMode: false,
	userClientBaseUrl: 'https://kramerius.domain.cz',
	deployPath: '',
	coreBaseUrl: 'https://kramerius.domain.cz/search',
	keycloak: {
		clientId: 'krameriusClient',
		logoutUrl:'https://eduid.domain.cz/realms/kramerius/protocol/openid-connect/logout?redirect_uri=https://kramerius-admin.domain.cz'
	},
	krameriusInstance: "kramerius7",
	proarc: [
		{
			name: "Produkce",
			domain: "https://proarc.domain.cz",
			krameriusInstance: "kramerius7" 
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