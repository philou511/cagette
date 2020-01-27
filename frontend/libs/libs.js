//
// npm dependencies library
//
(function(scope) {
  'use-strict';
  scope.__registry__ = Object.assign({}, scope.__registry__, {
    //
    // list npm modules required in Haxe
    //
    'bootstrap': require('bootstrap'),
    'react': require('react'),
    'redux': require('redux'),
    'react-avatar-editor': require('react-avatar-editor'),
    'react-dropzone': require('react-dropzone'),
    'react-redux': require('react-redux'),
    'prop-types': require('prop-types'),
    'react-dom': require('react-dom'),
    'react-dropzone': require('react-dropzone'),
    'react-avatar-editor': require('react-avatar-editor'),
    'leaflet': require('leaflet'),
    'react-leaflet': require('react-leaflet'),
    'react-places-autocomplete': require('react-places-autocomplete'),
    'geolib': require('geolib'),
    'react-router':require('react-router'),
    'react-router-dom':require('react-router-dom'),
    '@material-ui/core': require('@material-ui/core'),
    '@material-ui/core/styles': require('@material-ui/core/styles'),
    '@material-ui/pickers': require('@material-ui/pickers'),
    '@date-io/date-fns': require('@date-io/date-fns'),
    '@material-ui/icons': require('@material-ui/icons'),
    'date-fns': require('date-fns'),
    'date-fns/locale': require('date-fns/locale'),
    'date-fns/format': require('date-fns/format'),
    'stickyfilljs': require('stickyfilljs'),
    'sticky-events': require('sticky-events'),
    'intersection-observer': require('intersection-observer'),//Polyfill for stick-events to work
    'lodash.throttle': require('lodash.throttle'),
    'lodash.debounce': require('lodash.debounce'),
    'bowser': require('bowser'),//browser version detection
    
  });

  /*if (process.env.NODE_ENV !== 'production') {
    // enable React hot-reload
    require('haxe-modular');
  }*/

})(typeof $hx_scope != "undefined" ? $hx_scope : $hx_scope = {});
