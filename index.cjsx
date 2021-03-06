Promise = require 'bluebird'
async = Promise.coroutine
request = Promise.promisifyAll require('request')
{relative, join} = require 'path-extra'
path = require 'path-extra'
fs = require 'fs-extra'
{_, $, $$, React, ReactBootstrap, ROOT, resolveTime, layout, toggleModal} = window
{Table, ProgressBar, Grid, Input, Col, Alert} = ReactBootstrap
{APPDATA_PATH, SERVER_HOSTNAME} = window

i18n = require 'i18n'
{__} = i18n

i18n.configure
  locales: ['en-US', 'ja-JP', 'zh-CN']
  defaultLocale: 'zh-CN'
  directory: path.join(__dirname, 'assets', 'i18n')
  updateFiles: false
  indent: '\t'
  extension: '.json'
i18n.setLocale(window.language)


window.addEventListener 'layout.change', (e) ->
  {layout} = e.detail
getHpStyle = (percent) ->
  if percent <= 25
    'danger'
  else if percent <= 50
    'warning'
  else if percent <= 75
    'info'
  else
    'success'
module.exports =
  name: 'map-hp'
  priority: 8
  displayName: <span><FontAwesome key={0} name='heart' />{' ' + __("Map HP")}</span>
  description: __("Map HP")
  version: '1.0.0'
  author: 'Chiba'
  link: 'https://github.com/Chibaheit'
  reactClass: React.createClass
    getInitialState: ->
      mapHp: []
      clearedVisible: false
    handleResponse: (e) ->
      {method, path, body, postBody} = e.detail
      flag = false
      mapHp = []
      switch path
        when '/kcsapi/api_get_member/mapinfo'
          for mapInfo in body
            continue unless mapInfo.api_eventmap?
            now = if mapInfo.api_cleared > 0
              mapInfo.api_eventmap.api_max_maphp
            else
              mapInfo.api_eventmap.api_max_maphp - mapInfo.api_eventmap.api_now_maphp
            mapHp.push [mapInfo.api_id, now, mapInfo.api_eventmap.api_max_maphp]
          for mapInfo in body
            continue unless $maps[mapInfo.api_id].api_required_defeat_count
            now = if mapInfo.api_defeat_count?
              mapInfo.api_defeat_count
            else
              $maps[mapInfo.api_id].api_required_defeat_count
            mapHp.push [mapInfo.api_id, now, $maps[mapInfo.api_id].api_required_defeat_count]
          flag = true
      return unless flag
      @setState
        mapHp: mapHp
    handleSetClickValue: ->
      if @state.clearedVisible == false
        @setState
          clearedVisible: true
      else
        @setState
          clearedVisible: false

    componentDidMount: ->
      window.addEventListener 'game.response', @handleResponse
    componentWillUnmount: ->
      window.removeEventListener 'game.response', @handleResponse
    render: ->
      <div>
        <link rel="stylesheet" href={join(relative(ROOT, __dirname), 'assets', 'map-hp.css')} />
        {
          if @state.mapHp.length == 0
            <div>{__("Click Sortie to get infromation")}</div>
          else
            <div>
              <div style={display: 'flex', marginLeft: 15, marginRight: 15}>
                <Input type='checkbox' ref='clearedVisible' label={__("Show captured E0 map")} checked={@state.clearedVisible} onClick={@handleSetClickValue} />
              </div>
              <Table>
                <tbody>
                {
                  for info, i in @state.mapHp
                    [id, now, max] = info
                    res = max - now
                    continue if (((@state.clearedVisible == false) && (res == 0)) || ((@state.clearedVisible == true) && (id % 10 < 5)))
                    [
                      <tr key={i * 2}>
                        <td>
                          {if id // 10 > 20 then '[Event] ' else (if id % 10 > 4 then '[Extra] ' else '[Normal] ')}
                          {id // 10}-{id % 10}
                          {' ' + $maps[id].api_name}
                        </td>
                      </tr>
                      <tr key={i * 2 + 1}>
                        <td className="hp-progress">
                          <ProgressBar bsStyle={getHpStyle res / max * 100}
                                       now={res / max * 100}
                                       label={"#{res} / #{max}"}
                          />
                        </td>
                      </tr>
                    ]
                }
                </tbody>
              </Table>
            </div>
        }
      </div>
