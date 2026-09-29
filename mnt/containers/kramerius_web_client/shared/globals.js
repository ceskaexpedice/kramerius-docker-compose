var APP_GLOBAL = {
	share_url: "https://kramerius.domain.cz/uuid/${UUID}",
	//ga4: '',
	cookiebar: true,
	enablePeriodicalVolumesYearsLayout: true,
	enablePeriodicalIsssuesCalendarLayout: true,
	defaultPeriodicalVolumesLayout: "years",  // grid | years
	defaultPeriodicalIssuesLayout: "calendar",  // grid | calendar
	publicFilterDefault: false,
	advancedSearch: true,
	newestAll: true,
	landingPage: false,
	crossOrigin: false,
	citationServiceUrl: 'https://citace.digitalniknihovna.cz',
	actions: {
		pdf: 'always',
		print: 'always',
		jpeg: 'always',
		text: 'always',
		citation: 'always',
		metadata: 'always',
		share: 'always',
		selection: 'always',
		crop: 'always'
	},
	deployPath: '',
	bigHomeLogo: false,
	languages: ['cs', 'en'],
	aboutPage: {
		cs: '/assets/shared/pages/about.cs.html',
		en: '/assets/shared/pages/about.en.html'
	},
	krameriusList: [
		{
			title: 'K7',
			code: 'k7',
			logo: 'assets/shared/img/logo.png',
			url: 'https://kramerius.domain.cz',
			version: 7,
			adminClientUrl: 'https://kramerius-admin.domain.cz',
			keycloak: true,
			termsPage: {
				cs: '/assets/shared/terms/terms.cs.html',
				en: '/assets/shared/terms/terms.en.html'
			},
			termsPage2: {
				cs: '/assets/shared/terms/terms2.cs.html',
				en: '/assets/shared/terms/terms2.en.html'
			},
			termsUrl: {
				cs: '/assets/shared/terms/terms_of_use.cs.html',
				en: '/assets/shared/terms/terms_of_use.en.html'
			},
			richCollections: false,
			joinedDoctypes: false,
			lemmatization: false,
			iiif: true,
			ignorePolicyFlag: true,
			doctypes: ['monograph', 'periodical', 'map', 'graphic', 'archive', 'manuscript', 'soundrecording', 'sheetmusic', 'convolute', 'collection', 'museumExhibit'],
			//filters: ['access', 'licences', 'doctypes', 'authors', 'keywords', 'locations', 'languages'],
			filters: ['accessibility', 'licences', 'doctypes', 'authors', 'keywords', 'geonames', 'publishers', 'places', 'locations', 'genres', 'languages'],
			licences: {
				public: {
					access: 'open',
					label: {
						cs: 'Volná díla',
						en: 'Public domain'
					},
					message: {
						cs: '/assets/shared/licences/public.cs.html',
						en: '/assets/shared/licences/public.en.html'
					},
					bar: false,
					actions: {
						pdf: true,
						print: true,
						jpeg: true,
						text: true,
						citation: true,
						metadata: true,
						share: true,
						selection: true,
						crop: true
					}
				},
				dnnto: {
					access: 'login',
					label: {
						cs: 'Díla nedostupná na trhu online',
						en: 'Out of Commerce Works - online'
					},
					message: {
						cs: '/assets/shared/licences/dnnto.cs.html',
						en: '/assets/shared/licences/dnnto.en.html'
					},
					instruction: {
						cs: '/assets/shared/licences/dnnto.instruction.cs.html',
						en: '/assets/shared/licences/dnnto.instruction.en.html'
					},
					bar: true,
					actions: {
						pdf: false,
						print: false,
						jpeg: false,
						text: false,
						citation: true,
						metadata: true,
						share: true,
						selection: false,
						crop: false
					},
					watermark: {
						defaultText: 'DNNT',
						color: 'rgba(0, 0, 0, 0.3)',
						fontSize: 16,
						rowCount: 3,
						colCount: 5,
						probability: 75
					},
					image: '/assets/img/license_dnnto.png'
				},
				_private: {
					access: 'terminal',
					label: {
						cs: 'Dokument není veřejně dostupný',
						en: 'The document is not publicly accessible'
					},
					message: {
						cs: '/assets/shared/licences/_private.cs.html',
						en: '/assets/shared/licences/_private.en.html'
					},
					bar: false,
					actions: {
						pdf: false,
						print: true,
						jpeg: false,
						text: false,
						citation: true,
						metadata: true,
						share: true,
						selection: true,
						crop: false
					}
				},
				onsite: {
					access: 'terminal',
					label: {
						cs: 'Studovna',
						en: 'Study room'
					},
					message: {
						cs: '/assets/shared/licences/onsite.cs.html',
						en: '/assets/shared/licences/onsite.en.html'
					},
					instruction: {
						cs: '/assets/shared/licences/onsite.instruction.cs.html',
						en: '/assets/shared/licences/onsite.instruction.en.html',
					},
					bar: false,
					actions: {
						pdf: false,
						print: true,
						jpeg: false,
						text: false,
						citation: true,
						metadata: true,
						share: true,
						selection: true,
						crop: false
					}
				}
			}
		}
	]
};
