import { useState, useEffect, useCallback, useMemo, useRef } from 'react'
import { 
  IoVolumeHigh, 
  IoVolumeMedium, 
  IoVolumeLow, 
  IoVolumeOff,
  IoSearch,
  IoClose,
  IoPlay,
  IoStop,
  IoCopy,
  IoMusicalNotes,
  IoCheckmark,
  IoWarning,
  IoCheckmarkCircle,
  IoCar,
  IoSpeedometer,
  IoAlbums,
  IoChevronDown
} from 'react-icons/io5'

// ============================================================================
// UI COMPONENTS
// ============================================================================

function CustomSelect({ value, onChange, options, placeholder, className = "" }) {
  const [isOpen, setIsOpen] = useState(false)
  const ref = useRef(null)

  useEffect(() => {
    const handleClickOutside = (event) => {
      if (ref.current && !ref.current.contains(event.target)) {
        setIsOpen(false)
      }
    }
    document.addEventListener('mousedown', handleClickOutside)
    return () => document.removeEventListener('mousedown', handleClickOutside)
  }, [])

  const handleSelect = (val) => {
    // Mimic the event structure expected by the parent handlers
    onChange({ target: { value: val } })
    setIsOpen(false)
  }

  // Handle both object options {label, value} and string options
  const getLabel = (opt) => typeof opt === 'object' ? opt.label : opt
  const getValue = (opt) => typeof opt === 'object' ? opt.value : opt

  const selectedOption = options.find(opt => getValue(opt) === value)
  const displayLabel = selectedOption ? getLabel(selectedOption) : placeholder

  return (
    <div className={`custom-select ${className} ${isOpen ? 'open' : ''}`} ref={ref}>
      <button type="button" className="custom-select-trigger" onClick={() => setIsOpen(!isOpen)}>
        <span className="select-label">{displayLabel}</span>
        <IoChevronDown className="select-arrow" />
      </button>
      {isOpen && (
        <div className="custom-select-dropdown">
          {options.map((opt) => {
            const optValue = getValue(opt)
            const optLabel = getLabel(opt)
            return (
              <div 
                key={optValue} 
                className={`custom-select-option ${optValue === value ? 'selected' : ''}`}
                onClick={() => handleSelect(optValue)}
              >
                {optLabel}
                {optValue === value && <IoCheckmark className="option-check" />}
              </div>
            )
          })}
        </div>
      )}
    </div>
  )
}

// ============================================================================
// RESOLUTION SCALING
// ============================================================================

/**
 * Clamp a number between min and max
 */
function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n))
}

/**
 * Calculate UI scale based on viewport height
 * Uses 1080p as baseline, scales up to 2x for 4K displays
 */
function getUiScale() {
  const h = window.innerHeight || 1080
  const normalized = h / 1080
  return clamp(normalized, 1, 2)
}

/**
 * Apply the UI scale to CSS custom property
 */
function applyUiScale(value) {
  document.documentElement.style.setProperty('--es-ui-scale', value)
}

// ============================================================================
// NUI UTILITIES
// ============================================================================

/**
 * Get the parent resource name for NUI communication
 * Returns 'es_soundtester' in development mode
 */
function getResourceName() {
  if (typeof window.GetParentResourceName === 'function') {
    return window.GetParentResourceName()
  }
  return 'es_soundtester'
}

/**
 * Send a message to the Lua client script
 * Fixed: No longer causes stack overflow - properly fetches without recursion
 */
async function postNui(event, data = {}) {
  try {
    const resourceName = getResourceName()
    await fetch(`https://${resourceName}/${event}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data)
    })
  } catch (error) {
    // Silently fail in browser dev mode
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Simple fuzzy match - checks if all characters in query appear in text in order
 */
function fuzzyMatch(text, query) {
  if (!query) return true
  const lowerText = text.toLowerCase()
  const lowerQuery = query.toLowerCase()
  let queryIndex = 0
  
  for (let i = 0; i < lowerText.length && queryIndex < lowerQuery.length; i++) {
    if (lowerText[i] === lowerQuery[queryIndex]) {
      queryIndex++
    }
  }
  
  return queryIndex === lowerQuery.length
}

/**
 * Highlight matching characters in text
 */
function highlightMatch(text, query) {
  if (!query) return text
  
  const lowerText = text.toLowerCase()
  const lowerQuery = query.toLowerCase()
  const result = []
  let queryIndex = 0
  
  for (let i = 0; i < text.length; i++) {
    if (queryIndex < lowerQuery.length && lowerText[i] === lowerQuery[queryIndex]) {
      result.push(<span key={i} className="highlight">{text[i]}</span>)
      queryIndex++
    } else {
      result.push(text[i])
    }
  }
  
  return result
}

/**
 * Get volume icon based on level
 */
function getVolumeIcon(volume) {
  if (volume === 0) return IoVolumeOff
  if (volume < 0.33) return IoVolumeLow
  if (volume < 0.66) return IoVolumeMedium
  return IoVolumeHigh
}

// ============================================================================
// MAIN APP COMPONENT
// ============================================================================

function App() {
  // State
  const [isVisible, setIsVisible] = useState(false)
  const [isReady, setIsReady] = useState(false)
  const [sounds, setSounds] = useState([])
  const [soundSets, setSoundSets] = useState([])
  const [categories, setCategories] = useState([])
  const [buildInfo, setBuildInfo] = useState({})
  const [currentBuild, setCurrentBuild] = useState(1604)
  const [searchQuery, setSearchQuery] = useState('')
  const [debouncedSearch, setDebouncedSearch] = useState('')
  const [selectedSet, setSelectedSet] = useState('')
  const [selectedCategory, setSelectedCategory] = useState('')
  const [selectedIndex, setSelectedIndex] = useState(-1)
  const [volume, setVolume] = useState(1.0)
  const [isPlaying, setIsPlaying] = useState(false)
  const [copySuccess, setCopySuccess] = useState(false)
  const [lastPlayed, setLastPlayed] = useState(null)
  
  // Vehicle Audio State
  const [activeTab, setActiveTab] = useState('sounds') // 'sounds' or 'vehicles'
  const [vehicleCategories, setVehicleCategories] = useState([])
  const [selectedVehicleCategory, setSelectedVehicleCategory] = useState('')
  const [vehicleSearchQuery, setVehicleSearchQuery] = useState('')
  const [selectedVehicleIndex, setSelectedVehicleIndex] = useState(-1)
  const [vehicleRpm, setVehicleRpm] = useState(0.5)
  
  // Refs
  const searchInputRef = useRef(null)
  const soundListRef = useRef(null)
  const vehicleListRef = useRef(null)
  
  const [scrollInfo, setScrollInfo] = useState({ top: 0, height: 400 })
  
  // Debounce search input for better performance with large datasets
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(searchQuery)
    }, 100)
    return () => clearTimeout(timer)
  }, [searchQuery])
  
  // Filter sounds based on search, sound set, and category
  const filteredSounds = useMemo(() => {
    return sounds.filter(sound => {
      if (selectedSet && sound.set !== selectedSet) return false
      if (selectedCategory && sound.category !== selectedCategory) return false
      if (debouncedSearch && !fuzzyMatch(sound.sound, debouncedSearch) && !fuzzyMatch(sound.set, debouncedSearch)) return false
      return true
    })
  }, [sounds, debouncedSearch, selectedSet, selectedCategory])
  
  // Currently selected sound
  const selectedSound = useMemo(() => {
    if (selectedIndex >= 0 && selectedIndex < filteredSounds.length) {
      return filteredSounds[selectedIndex]
    }
    return null
  }, [filteredSounds, selectedIndex])
  
  // Filter vehicles based on search and category
  const filteredVehicles = useMemo(() => {
    let vehicles = []
    vehicleCategories.forEach(cat => {
      if (selectedVehicleCategory && cat.name !== selectedVehicleCategory) return
      cat.vehicles.forEach(v => {
        if (vehicleSearchQuery && !fuzzyMatch(v.label, vehicleSearchQuery) && !fuzzyMatch(v.audio, vehicleSearchQuery)) return
        vehicles.push({ ...v, category: cat.name })
      })
    })
    return vehicles
  }, [vehicleCategories, selectedVehicleCategory, vehicleSearchQuery])
  
  // Currently selected vehicle
  const selectedVehicle = useMemo(() => {
    if (selectedVehicleIndex >= 0 && selectedVehicleIndex < filteredVehicles.length) {
      return filteredVehicles[selectedVehicleIndex]
    }
    return null
  }, [filteredVehicles, selectedVehicleIndex])
  
  const { visibleSounds, soundStartIndex, soundPadTop, soundPadBottom } = useMemo(() => {
    const s = getUiScale()
    const rowH = (50 + 8) * s
    const basePad = 12 * s
    const total = filteredSounds.length
    const totalRows = Math.ceil(total / 3)
    const { top, height } = scrollInfo
    
    const startRow = Math.max(0, Math.floor(top / rowH) - 5)
    const endRow = Math.min(totalRows, Math.ceil((top + height) / rowH) + 5)
    const si = startRow * 3
    const ei = Math.min(total, endRow * 3)
    
    return {
      visibleSounds: filteredSounds.slice(si, ei),
      soundStartIndex: si,
      soundPadTop: basePad + startRow * rowH,
      soundPadBottom: basePad + Math.max(0, (totalRows - endRow) * rowH),
    }
  }, [filteredSounds, scrollInfo])
  
  const handleOpen = useCallback((data) => {
    setSounds(data.sounds || [])
    setSoundSets(data.soundSets || [])
    setCategories(data.categories || [])
    setBuildInfo(data.buildInfo || {})
    setVehicleCategories(data.vehicleAudio || [])
    setLastPlayed(data.lastPlayed)
    setCurrentBuild(data.currentBuild || 1604)
    setIsVisible(true)
    setIsReady(true)
    setSearchQuery('')
    setSelectedSet('')
    setSelectedCategory('')
    setSelectedIndex(data.sounds?.length > 0 ? 0 : -1)
    setVehicleSearchQuery('')
    setSelectedVehicleCategory('')
    setSelectedVehicleIndex(-1)
    setActiveTab('sounds')
    setScrollInfo({ top: 0, height: 400 })
    
    requestAnimationFrame(() => {
      searchInputRef.current?.focus()
    })
  }, [])
  
  // Handle closing the UI
  const handleClose = useCallback(() => {
    setIsReady(false)
    setIsVisible(false)
    postNui('stopSound')
    postNui('stopVehicleAudio')
    postNui('close')
  }, [])
  
  const handleSoundListScroll = useCallback((e) => {
    const el = e.currentTarget
    setScrollInfo({ top: el.scrollTop, height: el.clientHeight })
  }, [])
  
  // Play selected sound
  const playSound = useCallback(() => {
    if (!selectedSound) return
    
    setIsPlaying(true)
    setLastPlayed(selectedSound)
    postNui('playSound', {
      sound: selectedSound.sound,
      set: selectedSound.set,
      volume: volume,
      bank: selectedSound.bank
    })
  }, [selectedSound, volume])
  
  // Stop currently playing sound
  const stopSound = useCallback(() => {
    postNui('stopSound')
    setIsPlaying(false)
  }, [])
  
  // Play selected vehicle audio
  const playVehicleAudio = useCallback(() => {
    if (!selectedVehicle) return
    
    setIsPlaying(true)
    postNui('playVehicleAudio', {
      audio: selectedVehicle.audio,
      model: selectedVehicle.model,
      rpm: vehicleRpm,
      volume: 1.0
    })
  }, [selectedVehicle, vehicleRpm])
  
  // Stop vehicle audio
  const stopVehicleAudio = useCallback(() => {
    postNui('stopVehicleAudio')
    setIsPlaying(false)
  }, [])
  
  // Update vehicle RPM
  const updateVehicleRpm = useCallback((newRpm) => {
    setVehicleRpm(newRpm)
    postNui('setVehicleRpm', { rpm: newRpm })
  }, [])
  
  // Copy sound code to clipboard
  const copyToClipboard = useCallback(() => {
    if (!selectedSound) return
    
    let code
    if (selectedSound.bank) {
      code = `RequestScriptAudioBank("${selectedSound.bank}", false)\nPlaySoundFrontend(-1, "${selectedSound.sound}", "${selectedSound.set}", true)\nReleaseScriptAudioBank("${selectedSound.bank}")`
    } else {
      code = `PlaySoundFrontend(-1, "${selectedSound.sound}", "${selectedSound.set}", true)`
    }
    navigator.clipboard.writeText(code).then(() => {
      setCopySuccess(true)
      setTimeout(() => setCopySuccess(false), 1500)
      postNui('copyToClipboard', { text: code })
    }).catch(() => {
      // Fallback
      const textarea = document.createElement('textarea')
      textarea.value = code
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand('copy')
      document.body.removeChild(textarea)
      setCopySuccess(true)
      setTimeout(() => setCopySuccess(false), 1500)
    })
  }, [selectedSound])
  
  // Select a sound by index - auto-plays if already playing
  const selectSound = useCallback((index) => {
    if (index >= 0 && index < filteredSounds.length) {
      const wasPlaying = isPlaying && activeTab === 'sounds'
      setSelectedIndex(index)
      
      if (wasPlaying) {
        const sound = filteredSounds[index]
        if (sound) {
          postNui('playSound', {
            sound: sound.sound,
            set: sound.set,
            volume: volume,
            bank: sound.bank
          })
        }
      }
    }
  }, [filteredSounds, isPlaying, activeTab, volume])
  
  // Select a vehicle by index - auto-plays if already playing
  const selectVehicle = useCallback((index) => {
    if (index >= 0 && index < filteredVehicles.length) {
      const wasPlaying = isPlaying && activeTab === 'vehicles'
      setSelectedVehicleIndex(index)
      
      if (wasPlaying) {
        const vehicle = filteredVehicles[index]
        if (vehicle) {
          postNui('playVehicleAudio', {
            audio: vehicle.audio,
            model: vehicle.model,
            rpm: vehicleRpm,
            volume: 1.0
          })
        }
      }
    }
  }, [filteredVehicles, isPlaying, activeTab, vehicleRpm])
  
  // Keyboard navigation
  const handleKeyDown = useCallback((event) => {
    if (!isVisible) return
    
    // Focus search on /
    if (event.key === '/' && activeTab === 'sounds') {
      event.preventDefault()
      searchInputRef.current?.focus()
      return
    }
    
    // Copy on Shift+Enter
    if (event.key === 'Enter' && event.shiftKey) {
      event.preventDefault()
      copyToClipboard()
      return
    }
    
    switch (event.key) {
      case 'Escape':
        event.preventDefault()
        handleClose()
        break
      case 'Enter':
        event.preventDefault()
        if (activeTab === 'sounds') {
          playSound()
        } else {
          playVehicleAudio()
        }
        break
      case 'ArrowUp':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(prev => Math.max(0, prev - 3))
        } else {
          setSelectedVehicleIndex(prev => Math.max(0, prev - 3))
        }
        break
      case 'ArrowDown':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(prev => Math.min(filteredSounds.length - 1, prev + 3))
        } else {
          setSelectedVehicleIndex(prev => Math.min(filteredVehicles.length - 1, prev + 3))
        }
        break
      case 'ArrowLeft':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(prev => Math.max(0, prev - 1))
        } else {
          setSelectedVehicleIndex(prev => Math.max(0, prev - 1))
        }
        break
      case 'ArrowRight':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(prev => Math.min(filteredSounds.length - 1, prev + 1))
        } else {
          setSelectedVehicleIndex(prev => Math.min(filteredVehicles.length - 1, prev + 1))
        }
        break
      case 'PageUp':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(prev => Math.max(0, prev - 9))
        } else {
          setSelectedVehicleIndex(prev => Math.max(0, prev - 9))
        }
        break
      case 'PageDown':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(prev => Math.min(filteredSounds.length - 1, prev + 9))
        } else {
          setSelectedVehicleIndex(prev => Math.min(filteredVehicles.length - 1, prev + 9))
        }
        break
      case 'Home':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(0)
        } else {
          setSelectedVehicleIndex(0)
        }
        break
      case 'End':
        event.preventDefault()
        if (activeTab === 'sounds') {
          setSelectedIndex(Math.max(0, filteredSounds.length - 1))
        } else {
          setSelectedVehicleIndex(Math.max(0, filteredVehicles.length - 1))
        }
        break
    }
  }, [isVisible, activeTab, filteredSounds.length, filteredVehicles.length, handleClose, playSound, playVehicleAudio, copyToClipboard])
  
  useEffect(() => {
    if (selectedIndex < 0 || !soundListRef.current) return
    const s = getUiScale()
    const rowH = (50 + 8) * s
    const basePad = 12 * s
    const row = Math.floor(selectedIndex / 3)
    const itemTop = basePad + row * rowH
    const itemBottom = itemTop + 50 * s
    const el = soundListRef.current
    if (itemTop < el.scrollTop) {
      el.scrollTop = itemTop
    } else if (itemBottom > el.scrollTop + el.clientHeight) {
      el.scrollTop = itemBottom - el.clientHeight
    }
  }, [selectedIndex])
  
  useEffect(() => {
    if (filteredSounds.length > 0) {
      setSelectedIndex(0)
    } else {
      setSelectedIndex(-1)
    }
    if (soundListRef.current) {
      soundListRef.current.scrollTop = 0
    }
    setScrollInfo(prev => ({ ...prev, top: 0 }))
  }, [searchQuery, selectedSet, selectedCategory, sounds])
  
  // Reset vehicle selection when filter changes
  useEffect(() => {
    if (filteredVehicles.length > 0) {
      setSelectedVehicleIndex(0)
    } else {
      setSelectedVehicleIndex(-1)
    }
  }, [vehicleSearchQuery, selectedVehicleCategory, vehicleCategories]) // Added vehicleCategories
  
  // Scroll selected vehicle into view
  useEffect(() => {
    if (selectedVehicleIndex >= 0 && vehicleListRef.current) {
      const item = vehicleListRef.current.children[selectedVehicleIndex]
      if (item) {
        item.scrollIntoView({ block: 'nearest', behavior: 'auto' })
      }
    }
  }, [selectedVehicleIndex])
  
  // Listen for vehicleStopped message
  useEffect(() => {
    const handleMessage = (event) => {
      if (event.data.type === 'vehicleStopped') {
        setIsPlaying(false)
      }
    }
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [])
  
  // Apply resolution-based UI scaling
  useEffect(() => {
    applyUiScale(getUiScale())
    
    const handleResize = () => applyUiScale(getUiScale())
    window.addEventListener('resize', handleResize)
    return () => window.removeEventListener('resize', handleResize)
  }, [])
  
  // Listen for NUI messages
  useEffect(() => {
    const handleMessage = (event) => {
      const data = event.data
      
      switch (data.type) {
        case 'open':
          handleOpen(data)
          break
        case 'close':
          setIsVisible(false)
          break
      }
    }
    
    window.addEventListener('message', handleMessage)
    return () => window.removeEventListener('message', handleMessage)
  }, [handleOpen])
  
  // Listen for keyboard events
  useEffect(() => {
    document.addEventListener('keydown', handleKeyDown)
    return () => document.removeEventListener('keydown', handleKeyDown)
  }, [handleKeyDown])
  
  // Development mode - show mock data
  useEffect(() => {
    if (import.meta.env.DEV) {
      const mockSounds = [
        { sound: 'NAV_UP_DOWN', set: 'HUD_FRONTEND_DEFAULT_SOUNDSET', category: 'HUD & Frontend', build: 1604 },
        { sound: 'SELECT', set: 'HUD_FRONTEND_DEFAULT_SOUNDSET', category: 'HUD & Frontend', build: 1604 },
        { sound: 'BACK', set: 'HUD_FRONTEND_DEFAULT_SOUNDSET', category: 'HUD & Frontend', build: 1604 },
        { sound: 'ERROR', set: 'HUD_FRONTEND_DEFAULT_SOUNDSET', category: 'HUD & Frontend', build: 1604 },
        { sound: 'Text_Arrive_Tone', set: 'Phone_SoundSet_Default', category: 'Phone', build: 1604 },
        { sound: 'Hang_Up', set: 'Phone_SoundSet_Default', category: 'Phone', build: 1604 },
        { sound: 'WAYPOINT_SET', set: 'HUD_FRONTEND_DEFAULT_SOUNDSET', category: 'HUD & Frontend', build: 1604 },
        { sound: 'CHALLENGE_UNLOCKED', set: 'HUD_AWARDS', category: 'Awards & Mini-Games', build: 1604 },
        { sound: 'CASINO_LUCKY_WHEEL', set: 'DLC_CASINO_SOUNDSET', category: 'Diamond Casino DLC', build: 2060 },
        { sound: 'HEIST_PLANNING_BOARD', set: 'DLC_HEIST3_PLANNING_SOUNDSET', category: 'Casino Heist DLC', build: 2189 },
        { sound: 'CONTRACT_COMPLETE', set: 'DLC_TG_SOUNDSET', category: 'The Contract DLC', build: 2545 },
        { sound: 'FUTURE_SOUND', set: 'FUTURE_SOUNDSET', category: 'Future DLC', build: 9999 },
      ]
      const mockSets = ['HUD_FRONTEND_DEFAULT_SOUNDSET', 'Phone_SoundSet_Default', 'HUD_AWARDS', 'DLC_CASINO_SOUNDSET', 'DLC_HEIST3_PLANNING_SOUNDSET', 'DLC_TG_SOUNDSET', 'FUTURE_SOUNDSET']
      const mockCategories = ['HUD & Frontend', 'Phone', 'Awards & Mini-Games', 'Diamond Casino DLC', 'Casino Heist DLC', 'The Contract DLC', 'Future DLC']
      const mockBuildInfo = {
        1604: { name: 'Arena War', date: 'December 2018' },
        2060: { name: 'Los Santos Summer Special', date: 'August 2020' },
        2189: { name: 'Cayo Perico Heist', date: 'December 2020' },
        2545: { name: 'The Contract', date: 'December 2021' },
        9999: { name: 'Future Build', date: 'TBD' }
      }
      
      handleOpen({ 
        sounds: mockSounds, 
        soundSets: mockSets,
        categories: mockCategories,
        buildInfo: mockBuildInfo,
        currentBuild: 2545
      })
    }
  }, [handleOpen])
  
  // Volume icon component
  const VolumeIcon = getVolumeIcon(volume)
  
  if (!isVisible) return null
  
  return (
    <div className={`sound-tester-app ${isReady ? 'ready' : ''}`}>
      <div className="sound-tester-panel">
        {/* Header */}
        <div className="panel-header">
          <div className="header-title">
            <IoMusicalNotes className="icon" />
            <h1>Cortex Sound Tester</h1>
          </div>
          <div className="header-actions">
            <span className="sound-count">
              {activeTab === 'sounds' 
                ? `${filteredSounds.length.toLocaleString()} / ${sounds.length.toLocaleString()} sounds` 
                : `${filteredVehicles.length.toLocaleString()} vehicles`}
            </span>
            <button className="close-btn" onClick={handleClose}>
              <IoClose />
            </button>
          </div>
        </div>
        
        {/* Tab Switcher */}
        <div className="tab-switcher">
          <button 
            className={`tab-btn ${activeTab === 'sounds' ? 'active' : ''}`}
            onClick={() => { setActiveTab('sounds'); setIsPlaying(false); postNui('stopSound'); postNui('stopVehicleAudio') }}
          >
            <IoMusicalNotes />
            <span>Sounds</span>
          </button>
          <button 
            className={`tab-btn ${activeTab === 'vehicles' ? 'active' : ''}`}
            onClick={() => { setActiveTab('vehicles'); setIsPlaying(false); postNui('stopSound'); postNui('stopVehicleAudio') }}
          >
            <IoCar />
            <span>Vehicles</span>
          </button>
        </div>
        
        {activeTab === 'sounds' ? (
          <>
            {/* Controls */}
            <div className="controls-section">
              {/* Search & Filter Row */}
              <div className="search-row">
                <div className="search-container">
                  <IoSearch className="search-icon" />
                  <input
                    ref={searchInputRef}
                    type="text"
                    className="search-input"
                    placeholder="Search sounds or sets..."
                    value={searchQuery}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    autoComplete="off"
                  />
                </div>
                <CustomSelect
                  className="filter-select"
                  value={selectedSet}
                  onChange={(e) => setSelectedSet(e.target.value)}
                  options={[{ value: '', label: 'All Sound Sets' }, ...soundSets.map(s => ({ value: s, label: s }))]}
                  placeholder="All Sound Sets"
                />
              </div>
              
              {/* Category Filter Row */}
              <div className="filter-row">
                <CustomSelect
                  className="filter-select category-select"
                  value={selectedCategory}
                  onChange={(e) => setSelectedCategory(e.target.value)}
                  options={[{ value: '', label: 'All Categories' }, ...categories.map(c => ({ value: c, label: c }))]}
                  placeholder="All Categories"
                />
                <div className="build-info">
                  <span className="build-label">Build:</span>
                  <span className="build-value">{currentBuild}</span>
                </div>
              </div>
          
          {/* Volume Control Row */}
          <div className="volume-row">
            <div className="volume-label">
              <VolumeIcon className="icon" />
              <span>Volume</span>
            </div>
            <input
              type="range"
              className="volume-slider"
              min="0"
              max="1"
              step="0.01"
              value={volume}
              onChange={(e) => setVolume(parseFloat(e.target.value))}
            />
            <span className="volume-value">{Math.round(volume * 100)}%</span>
          </div>
        </div>
        
        {/* Media Controls Section - Compact */}
        <div className="media-controls">
          <div className="media-buttons">
            <button 
              className={`media-btn play ${isPlaying ? 'active' : ''}`}
              onClick={playSound}
              disabled={!selectedSound}
              title="Play sound"
            >
              <IoPlay />
            </button>
            <button 
              className="media-btn stop"
              onClick={stopSound}
              title="Stop sound"
            >
              <IoStop />
            </button>
          </div>
          
          <div className="media-info">
            {selectedSound ? (
              <>
                <span className="media-sound-name">{selectedSound.sound}</span>
                <span className="media-separator">|</span>
                <span className="media-sound-set">{selectedSound.set}</span>
                {selectedSound.bank && (
                  <>
                    <span className="media-separator">|</span>
                    <span className="media-bank" title={`Audio bank: ${selectedSound.bank}`}>
                      <IoAlbums className="bank-icon" />
                      {selectedSound.bank}
                    </span>
                  </>
                )}
              </>
            ) : (
              <span className="media-none">No sound selected</span>
            )}
          </div>
          
          {isPlaying && (
            <div className="media-status">
              <div className="media-status-indicator"></div>
            </div>
          )}
        </div>
        
        {/* Sound List */}
        <div className="sound-list-container">
          <div className="sound-list" ref={soundListRef} onScroll={handleSoundListScroll}>
            {filteredSounds.length === 0 ? (
              <div className="empty-state">
                <IoMusicalNotes className="icon" />
                <div className="empty-state-text">No sounds found</div>
              </div>
            ) : (
              <div className="sound-list-grid" style={{ paddingTop: soundPadTop, paddingBottom: soundPadBottom }}>
                {visibleSounds.map((sound, i) => {
                  const index = soundStartIndex + i
                  const isCompatible = !sound.build || sound.build <= currentBuild
                  return (
                  <div
                    key={`${sound.sound}-${sound.set}-${index}`}
                    className={`sound-item ${index === selectedIndex ? 'selected' : ''} ${isPlaying && index === selectedIndex ? 'playing' : ''} ${!isCompatible ? 'incompatible' : ''}`}
                    onClick={() => selectSound(index)}
                    onDoubleClick={playSound}
                  >
                    <span className="sound-index">{index + 1}</span>
                    <div className="sound-item-content">
                      <div className="sound-name-row">
                        <span className="sound-name">
                          {highlightMatch(sound.sound, searchQuery)}
                        </span>
                        {sound.build && (
                          <span className={`build-badge ${isCompatible ? 'compatible' : 'incompatible'}`} title={isCompatible ? 'Compatible with current build' : `Requires build ${sound.build}+`}>
                            {isCompatible ? <IoCheckmarkCircle /> : <IoWarning />}
                            <span className="build-badge-text">{sound.build}</span>
                          </span>
                        )}
                      </div>
                      <div className="sound-meta">
                        <span className="sound-set">{sound.set}</span>
                        {sound.category && (
                          <>
                            <span className="meta-separator">|</span>
                            <span className="sound-category">{sound.category}</span>
                          </>
                        )}
                        {sound.bank && (
                          <>
                            <span className="meta-separator">|</span>
                            <span className="sound-bank" title={`Requires audio bank: ${sound.bank}`}>
                              <IoAlbums className="bank-icon" />
                              {sound.bank}
                            </span>
                          </>
                        )}
                      </div>
                    </div>
                    <button 
                      className="sound-item-play"
                      onClick={(e) => {
                        e.stopPropagation()
                        selectSound(index)
                        setIsPlaying(true)
                        const s = filteredSounds[index]
                        if (s) {
                          postNui('playSound', {
                            sound: s.sound,
                            set: s.set,
                            volume: volume,
                            bank: s.bank
                          })
                        }
                      }}
                    >
                      <IoPlay />
                    </button>
                  </div>
                  )
                })}
              </div>
            )}
          </div>
        </div>
        
        {/* Footer Actions */}
        <div className="panel-footer">
          <button
            className="action-btn primary"
            disabled={!selectedSound}
            onClick={playSound}
          >
            <IoPlay />
            <span>Play</span>
          </button>
          <button
            className="action-btn secondary"
            disabled={!selectedSound}
            onClick={copyToClipboard}
          >
            {copySuccess ? <IoCheckmark /> : <IoCopy />}
            <span>{copySuccess ? 'Copied' : 'Copy'}</span>
          </button>
        </div>
          </>
        ) : (
          <>
            {/* Vehicle Controls */}
            <div className="controls-section">
              <div className="search-row">
                <div className="search-container">
                  <IoSearch className="search-icon" />
                  <input
                    type="text"
                    className="search-input"
                    placeholder="Search vehicles..."
                    value={vehicleSearchQuery}
                    onChange={(e) => setVehicleSearchQuery(e.target.value)}
                    autoComplete="off"
                  />
                </div>
                <CustomSelect
                  className="filter-select"
                  value={selectedVehicleCategory}
                  onChange={(e) => setSelectedVehicleCategory(e.target.value)}
                  options={[{ value: '', label: 'All Types' }, ...vehicleCategories.map(c => ({ value: c.name, label: c.name }))]}
                  placeholder="All Types"
                />
              </div>
              
              {/* RPM Control */}
              <div className="volume-row">
                <div className="volume-label">
                  <IoSpeedometer className="icon" />
                  <span>RPM</span>
                </div>
                <input
                  type="range"
                  className="volume-slider rpm-slider"
                  min="0.1"
                  max="0.99"
                  step="0.01"
                  value={vehicleRpm}
                  onChange={(e) => updateVehicleRpm(parseFloat(e.target.value))}
                />
                <span className="volume-value">{Math.round(vehicleRpm * 100)}%</span>
              </div>
            </div>
            
            {/* Vehicle Media Controls - Compact */}
            <div className="media-controls">
              <div className="media-buttons">
                <button 
                  className={`media-btn play ${isPlaying ? 'active' : ''}`}
                  onClick={playVehicleAudio}
                  disabled={!selectedVehicle}
                  title="Play vehicle audio"
                >
                  <IoPlay />
                </button>
                <button 
                  className="media-btn stop"
                  onClick={stopVehicleAudio}
                  title="Stop audio"
                >
                  <IoStop />
                </button>
              </div>
              
              <div className="media-info">
                {selectedVehicle ? (
                  <>
                    <span className="media-sound-name">{selectedVehicle.label}</span>
                    <span className="media-separator">|</span>
                    <span className="media-sound-set">{selectedVehicle.audio}</span>
                  </>
                ) : (
                  <span className="media-none">No vehicle selected</span>
                )}
              </div>
              
              {isPlaying && (
                <div className="media-status">
                  <div className="media-status-indicator"></div>
                </div>
              )}
            </div>
            
            {/* Vehicle List */}
            <div className="sound-list-container">
              <div className="sound-list" ref={vehicleListRef}>
                {filteredVehicles.length === 0 ? (
                  <div className="empty-state">
                    <IoCar className="icon" />
                    <div className="empty-state-text">No vehicles found</div>
                  </div>
                ) : (
                  filteredVehicles.map((vehicle, index) => (
                    <div
                      key={`${vehicle.audio}-${index}`}
                      className={`sound-item ${index === selectedVehicleIndex ? 'selected' : ''} ${isPlaying && index === selectedVehicleIndex ? 'playing' : ''}`}
                      onClick={() => selectVehicle(index)}
                      onDoubleClick={playVehicleAudio}
                    >
                      <span className="sound-index">{index + 1}</span>
                      <div className="sound-item-content">
                        <div className="sound-name-row">
                          <span className="sound-name">
                            {highlightMatch(vehicle.label, vehicleSearchQuery)}
                          </span>
                        </div>
                        <div className="sound-meta">
                          <span className="sound-set">{vehicle.audio}</span>
                          <span className="meta-separator">|</span>
                          <span className="sound-category">{vehicle.category}</span>
                        </div>
                      </div>
                      <button 
                        className="sound-item-play"
                        onClick={(e) => {
                          e.stopPropagation()
                          setSelectedVehicleIndex(index)
                          setTimeout(() => {
                            const vehicle = filteredVehicles[index]
                            if (vehicle) {
                              setIsPlaying(true)
                              postNui('playVehicleAudio', {
                                audio: vehicle.audio,
                                model: vehicle.model,
                                rpm: vehicleRpm,
                                volume: 1.0
                              })
                            }
                          }, 0)
                        }}
                      >
                        <IoPlay />
                      </button>
                    </div>
                  ))
                )}
              </div>
            </div>
            
            {/* Vehicle Footer */}
            <div className="panel-footer">
              <button
                className="action-btn primary"
                disabled={!selectedVehicle}
                onClick={playVehicleAudio}
              >
                <IoPlay />
                <span>Play</span>
              </button>
              <button
                className="action-btn secondary"
                onClick={stopVehicleAudio}
              >
                <IoStop />
                <span>Stop</span>
              </button>
            </div>
          </>
        )}
        
        {/* Keyboard Shortcuts */}
        <div className="shortcuts-bar">
          <div className="shortcut">
            <kbd>ESC</kbd>
            <span>Close</span>
          </div>
          <div className="shortcut">
            <kbd>Enter</kbd>
            <span>Play</span>
          </div>
          <div className="shortcut">
            <kbd>Shift+Enter</kbd>
            <span>Copy Code</span>
          </div>
          <div className="shortcut">
            <kbd>&#8593;&#8595;</kbd>
            <span>Navigate</span>
          </div>
          <div className="shortcut">
            <kbd>PgUp/PgDn</kbd>
            <span>Jump</span>
          </div>
          <div className="shortcut">
            <kbd>/</kbd>
            <span>Search</span>
          </div>
        </div>
      </div>
    </div>
  )
}

export default App
