require! {
  # Vendor
  './globals.ls'

  # Pages
  './pages/home.ls': Home

  # Styles
  './vendor/css/normalize.css'
  './styles/app.scss'
}

ReactDOM.render $(Home)!, document.get-element-by-id('root')

# TODO:
# - convert all underscores in IDs and classes to dashes
