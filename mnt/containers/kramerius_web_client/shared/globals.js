var APP_GLOBAL = {
  share_url: "https://k7.inovatika.dev/uuid/${UUID}",
  ga: '',
  googleMapsApiKey: 'AIzaSyCGDIOYeh5bw_vsBcZxZH3GOzmA0aetqBw',
  enablePeriodicalVolumesYearsLayout: true,
  enablePeriodicalIsssuesCalendarLayout: true,
  defaultPeriodicalVolumesLayout: "years", // grid | years
  defaultPeriodicalIssuesLayout: "calendar", // grid | calendar
  publicFilterDefault: false,
  krameriusLogin: false,
  bigHomeLogo: false,
  hideHomeTitle: false,
  advancedSearch: false,
  landingPage: false,
  crossOrigin: false,
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
  krameriusList: [
    {
      title: 'K7',
      code: 'k7',
      logo: 'assets/img/logo.png',
      url: 'https://k7.inovatika.dev',
      version: 7,
      adminClientUrl: 'https://admin.k7.inovatika.dev',
      keycloak: {
        baseUrl: 'https://k7.inovatika.dev/auth',
        secret: 'sCaLaWHXz4SEWhzmIRYBtfxPhTdY7qcC',
        clientId: 'krameriusClient'
      },
      richCollections: false,
      joinedDoctypes: false,
      lemmatization: false,
      iiif: true,
      mapSearch: true,
      customRightMessage: true,
      ignorePolicyFlag:true,
      	    
      doctypes: ['periodical', 'monograph', 'map', 'graphic', 'archive', 'manuscript', 'soundrecording', 'sheetmusic', 'convolute', 'collection', 'museumExhibit'],
      filters: ['access', 'licences', 'doctypes', 'authors', 'keywords', 'geonames', 'publishers', 'places', 'locations', 'genres', 'languages'],
      licences: {
	"cover-and-content":{

   	  label: {
            cs: 'Cover and content',
            en: 'Cover and content'
          },
          message: {
            cs: '/assets/shared/licences/dnnto.cs.html',
            en: '/assets/shared/licences/dnnto.en.html'
          },
          image: '/assets/img/cover-and-content.png',
          bar: false,
          actions: {
            pdf: false,
            print: true,
            jpeg: true,
            text: true,
            citation: true,
            metadata: true,
            share: true,
            selection: true,
            crop: true
          },
          watermark: {
            defaultText: 'SPECIAL-NEEEDS',
            color: 'rgba(0, 0, 0, 0.3)',
            fontSize: 16,
            rowCount: 3,
            colCount: 5,
            probability: 75
          }
 

	},
	"special-needs":{

          label: {
            cs: 'Special needs',
            en: 'Special needs'
          },
          message: {
            cs: '/assets/shared/licences/dnnto.cs.html',
            en: '/assets/shared/licences/dnnto.en.html'
          },
          image: '/assets/img/special-needs.png',
          bar: false,
          actions: {
            pdf: false,
            print: true,
            jpeg: true,
            text: true,
            citation: true,
            metadata: true,
            share: true,
            selection: true,
            crop: true
          },
          watermark: {
            defaultText: 'SPECIAL-NEEEDS',
            color: 'rgba(0, 0, 0, 0.3)',
            fontSize: 16,
            rowCount: 3,
            colCount: 5,
            probability: 75
          }
 
	},
        dnnto: {
          label: {
            cs: 'Díla nedostupná na trhu',
            en: 'Out of Commerce Works'
          },
          message: {
            cs: '/assets/shared/licences/dnnto.cs.html',
            en: '/assets/shared/licences/dnnto.en.html'
          },
          bar: true,
          actions: {
            pdf: false,
            print: true,
            jpeg: true,
            text: true,
            citation: true,
            metadata: true,
            share: true,
            selection: true,
            crop: true
          },
          watermark: {
            defaultText: 'DNNT',
            color: 'rgba(0, 0, 0, 0.3)',
            fontSize: 16,
            rowCount: 3,
            colCount: 5,
            probability: 75
          }
        },
         "public": {
          "access":'open',		  
          label: {
            cs: 'Volná díla',
            en: 'Public domain'
          },
          message: {
            cs: '/assets/shared/licences/dnnto.cs.html',
            en: '/assets/shared/licences/dnnto.en.html'
          },
          bar: false,
          actions: {
            pdf: false,
            print: false,
            jpeg: false,
            text: true,
            citation: true,
            metadata: true,
            share: true,
            selection: false,
            crop: true
          }

        },
        
	 onsite: {
          access: 'terminal',
          label: {
            cs: 'Studovna',
            en: 'Studovna',
            de: 'Studovna',
            sk: 'Ĺ tudovĹa'
          },
          message: {
            cs: '/assets/shared/licences/mzk/onsite.cs.html',
            en: '/assets/shared/licences/mzk/onsite.en.html',
            de: '/assets/shared/licences/mzk/onsite.en.html',
            sk: '/assets/shared/licences/mzk/onsite.cs.html'
          },
          instruction: {
            cs: '/assets/shared/licences/mzk/onsite.instruction.cs.html',
            en: '/assets/shared/licences/mzk/onsite.instruction.en.html'
          },
          bar: false,
          actions: {
            pdf: false,
            print: false,
            jpeg: false,
            text: false,
            citation: true,
            metadata: true,
            share: true,
            selection: true,
            crop: false
          }
        },  

	      _private: {
          label: {
            cs: 'Dokument není veřejně dostupný',
            en: 'The document is not publicly accessible'
          },
          message: {
            cs: '/assets/shared/licences/_private.cs.html',
            en: '/assets/shared/licences/_private.en.html'
          }
        }
      }
    }
  ]
}
