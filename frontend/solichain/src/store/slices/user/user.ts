import { createSlice } from "@reduxjs/toolkit";
import { RootState } from "../../store";
import type { PayloadAction } from "@reduxjs/toolkit";

const USER = {
  id: "";
  token: "",
  refreshToken: "",
  email: "",
  isLoggedIn: false,
  marketplaceAlertRead: false,
};

/**
 * Initial state will be dispatched.
 * @constant {Object} USER.
 */
const userSlice = createSlice({
  name: "user",
  initialState: null,
  reducers: {
    setUser(state: any, action: PayloadAction<any>) {
      return {
        ...state,
        ...action.payload,
      };
    },
    setMarketplaceAlertRead: (state: any, action: PayloadAction<any>) => {
      state.marketplaceAlertRead = action.payload;
    },
  },
});

export const selectUser = (state: RootState) => state.user;

export const { setUser, setMarketplaceAlertRead } = userSlice.actions;

export default userSlice.reducer;
