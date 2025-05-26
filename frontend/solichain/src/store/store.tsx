import { combineReducers, configureStore } from '@reduxjs/toolkit';
import { Provider } from 'react-redux';
import { persistReducer, persistStore } from 'redux-persist';
import { PersistGate } from 'redux-persist/integration/react';
import storage from 'redux-persist/lib/storage';

import user from './slices/user/user';


const persistConfig = {
  key: 'root',
  storage,
};

const rootReducer = combineReducers({
  user
});

export const persistedReducer = persistReducer(persistConfig, rootReducer);

export const store = configureStore({
  reducer: persistedReducer
});

// persistor typo is built in keyword in the library
// check PersistGate component down in the same file
const persistor = persistStore(store);

/**
 * Uses the store to provide the updated state to the application.
 * Wrap its children with a Provider hols the store.
 * @param {Node} props .
 *
 * @component
 */
interface IProps {
  children: React.ReactNode;
}

export const Store = (props: IProps) => {
  const { children } = props;
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        {children}
      </PersistGate>
    </Provider>
  );
};


export type AppDispatch = typeof store.dispatch;

export type RootState = ReturnType<typeof store.getState>;
