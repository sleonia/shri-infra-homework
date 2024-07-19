ARG PORT
ARG NODE_VERSION

FROM node:${NODE_VERSION}-alpine as base
WORKDIR /usr/app

FROM base as prod_deps
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev

FROM prod_deps as build_ui
RUN --mount=type=bind,source=package.json,target=package.json \
    --mount=type=bind,source=package-lock.json,target=package-lock.json \
    --mount=type=cache,target=/root/.npm \
    npm ci
COPY . .
RUN npm run build

FROM base as build
COPY package.json .
COPY ./src/server/. ./src/server
COPY ./src/common/. ./src/common
COPY --from=prod_deps /usr/app/node_modules ./node_modules
COPY --from=build_ui /usr/app/dist ./dist

FROM build as final
ENV NODE_ENV production
USER node
EXPOSE ${PORT}
CMD npm start